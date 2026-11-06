#!/usr/bin/env python3
"""从工作流文件推导出所需的 custom_nodes 包，输出可直接给 launch.sh 用的白名单。

用法：
    python whitelist_from_workflow.py 工作流.json [更多工作流.json ...]
    python whitelist_from_workflow.py "user/default/workflows/KREA2/[T2I] Simple New.json" --write whitelist_nodes.sh
    python whitelist_from_workflow.py 工作流.json --json
    python whitelist_from_workflow.py 工作流.json --verbose         # 打印每个节点由哪个包提供
    python whitelist_from_workflow.py 工作流.json --method static   # 不加载 ComfyUI，纯源码扫描（会误报）

两种映射方式：
    dynamic（默认）  在本进程里加载一次 ComfyUI 的全部自定义节点，用真实节点注册表拿到
                     每个节点的来源包。准确，代价是启动约 20-40 秒且需要能初始化 CUDA。
    static           只扫描源码里的字符串字面量。秒级、不需要 GPU，但会把「引用了别的包
                     节点名」的包（PromptChain、mcp-panel 之类）误判成提供方，仅作兜底。

解析工作流时会一并收集 definitions.subgraphs 里内嵌子图的节点；子图自身的 UUID 不是节点。
"""

from __future__ import annotations

import argparse
import asyncio
import io
import json
import logging
import os
import re
import sys

SCRIPT_PATH = os.path.abspath(__file__)
REPO_ROOT = os.path.dirname(SCRIPT_PATH)
CUSTOM_NODES_DIR = os.path.join(REPO_ROOT, "custom_nodes")
VENV_PYTHON = os.path.join(REPO_ROOT, ".venv", "bin", "python")
# 记下真实 stdout：加载自定义节点后会把 sys.stdout 换成缓冲区，用来吞掉
# 自定义节点（以及它们后台线程在退出时）的打印，保证结果输出干净。
REAL_STDOUT = sys.stdout


def ensure_venv_python() -> None:
    """dynamic 模式需要 ComfyUI 的依赖，若当前不是 venv python 就自动换过去重跑。"""
    if os.environ.get("WHITELIST_REEXEC") == "1":
        return
    if not os.path.exists(VENV_PYTHON):
        return
    # venv 里的 python 常常是系统解释器的符号链接，realpath 比不出来，改比 sys.prefix
    venv_prefix = os.path.dirname(os.path.dirname(VENV_PYTHON))
    if os.path.realpath(sys.prefix) == os.path.realpath(venv_prefix):
        return
    env = dict(os.environ, WHITELIST_REEXEC="1")
    os.execve(VENV_PYTHON, [VENV_PYTHON, SCRIPT_PATH, *sys.argv[1:]], env)

# 前端内置节点：由 ComfyUI 前端注册，没有后端实现，也不需要白名单。
# 注意 Bookmark/Label 这类虽然也是前端节点，但由具体节点包的前端扩展提供，不能算在内。
FRONTEND_ONLY = {
    "Note", "MarkdownNote", "Reroute", "RerouteNode", "PrimitiveNode",
    "SetNode", "GetNode",
}

SKIP_DIRS = {".git", "node_modules", "__pycache__", ".venv", "venv", ".mypy_cache", ".pytest_cache"}
SKIP_NAME_PREFIX = ("test_", "test-", "conftest")
SKIP_PATH_PARTS = ("/tests/", "/test/", "/browser_tests/", "/examples/", "/docs/", "/screenshots/")
SOURCE_EXTS = (".py", ".js", ".mjs", ".ts")
MAX_FILE_BYTES = 4 * 1024 * 1024
LITERAL_RE = re.compile(r"""["'`]([^"'`\n\\]{2,100})["'`](\s*:?)""")


def collect_node_types(workflow_path: str) -> set[str]:
    """收集工作流里出现的全部节点类型（含内嵌子图），排除子图自身的 UUID。"""
    with open(workflow_path, encoding="utf-8") as f:
        data = json.load(f)

    local_ids: set[str] = set()
    types: set[str] = set()

    def scan_defs(definitions) -> None:
        for sub in (definitions or {}).get("subgraphs") or []:
            if isinstance(sub, dict):
                if sub.get("id"):
                    local_ids.add(sub["id"])
                scan_defs(sub.get("definitions"))

    def scan_nodes(node_list) -> None:
        for node in node_list or []:
            if isinstance(node, dict) and isinstance(node.get("type"), str):
                types.add(node["type"])

    scan_defs(data.get("definitions"))
    scan_nodes(data.get("nodes"))
    for sub in (data.get("definitions") or {}).get("subgraphs") or []:
        if isinstance(sub, dict):
            scan_nodes(sub.get("nodes"))
    return {t for t in types if t not in local_ids}


# ---------------------------------------------------------------- dynamic 方式

class _StubAssetManager:
    """数据库被别的 ComfyUI 占用时用的占位资源管理器，只为让 PromptServer 能构造出来。"""
    enabled = False

    def register_routes(self, *args, **kwargs):
        pass

    def set_event_sink(self, *args, **kwargs):
        pass

    def ensure_scan_started(self):
        pass


def build_index_dynamic() -> dict[str, str] | None:
    """加载全部自定义节点，返回 {节点类型: 提供它的包}；核心节点映射为空字符串。"""
    saved_argv = sys.argv
    saved_stdout = sys.stdout
    try:
        sys.argv = [saved_argv[0]]  # 别让本脚本的参数被 ComfyUI 的 cli_args 解析
        logging.disable(logging.CRITICAL)
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        import server  # noqa: E402
        import nodes  # noqa: E402

        try:
            from app.assets.manager import default_asset_manager
            asset_manager = default_asset_manager()
        except Exception:
            asset_manager = _StubAssetManager()

        server.PromptServer(loop, asset_manager)
        sys.stdout = io.StringIO()  # 自定义节点加载时会大量打印，先吞掉
        # 这里故意不恢复 sys.stdout：自定义节点的后台线程会在进程退出时继续打印，
        # 保持重定向才能让最终结果（写到 REAL_STDOUT）保持干净。
        loop.run_until_complete(
            nodes.init_extra_nodes(init_custom_nodes=True, init_api_nodes=False)
        )

        mapping: dict[str, str] = {}
        for node_type, cls in nodes.NODE_CLASS_MAPPINGS.items():
            module = getattr(cls, "RELATIVE_PYTHON_MODULE", None) or cls.__module__
            match = re.match(r"custom_nodes\.([^.]+)", module)
            if not match:
                mapping[node_type] = ""  # 核心节点
                continue
            raw = match.group(1)
            for name in os.listdir(CUSTOM_NODES_DIR):
                if name.lower() == raw.lower():
                    raw = name
                    break
            mapping[node_type] = raw
        return mapping
    except Exception as exc:  # 没有 GPU、依赖缺失等
        sys.stdout = saved_stdout
        print(f"[warn] 加载真实节点注册表失败，改用静态扫描（结果可能有误报）：{exc}", file=sys.stderr)
        print(f"[hint] 建议用 ComfyUI 的 venv 运行：{VENV_PYTHON} {SCRIPT_PATH} ...", file=sys.stderr)
        return None
    finally:
        sys.argv = saved_argv


# ----------------------------------------------------------------- static 方式

def _iter_source_files(root_dir: str):
    for root, dirs, files in os.walk(root_dir):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        norm = root.replace(os.sep, "/") + "/"
        if any(part in norm for part in SKIP_PATH_PARTS):
            continue
        for name in files:
            if not name.endswith(SOURCE_EXTS) or name.startswith(SKIP_NAME_PREFIX):
                continue
            path = os.path.join(root, name)
            try:
                if os.path.getsize(path) > MAX_FILE_BYTES:
                    continue
            except OSError:
                continue
            yield path


def _pack_literals(pack_dir: str) -> tuple[set[str], set[str]]:
    all_literals: set[str] = set()
    key_literals: set[str] = set()
    for path in _iter_source_files(pack_dir):
        try:
            text = open(path, encoding="utf-8", errors="ignore").read()
        except OSError:
            continue
        for literal, tail in LITERAL_RE.findall(text):
            all_literals.add(literal)
            if tail.strip().startswith(":"):
                key_literals.add(literal)
    return all_literals, key_literals


def build_index_static() -> dict[str, str]:
    """扫描源码字面量，返回 {节点类型: 提供它的包}。会有误报，仅作兜底。"""
    pack_literals = {}
    for name in sorted(os.listdir(CUSTOM_NODES_DIR)):
        pack_dir = os.path.join(CUSTOM_NODES_DIR, name)
        if os.path.isdir(pack_dir) and not name.endswith(".disabled"):
            pack_literals[name] = _pack_literals(pack_dir)

    core_literals: set[str] = set()
    for rel in ("nodes.py", "comfy_extras", "comfy_api_nodes", "comfy_api"):
        path = os.path.join(REPO_ROOT, rel)
        if os.path.isfile(path):
            files = [path]
        elif os.path.isdir(path):
            files = list(_iter_source_files(path))
        else:
            files = []
        for f in files:
            if not f.endswith(".py"):
                continue
            try:
                core_literals.update(
                    m.group(1) for m in LITERAL_RE.finditer(open(f, encoding="utf-8", errors="ignore").read())
                )
            except OSError:
                pass

    mapping: dict[str, str] = {}
    for pack, (_all_literals, key_literals) in pack_literals.items():
        for literal in key_literals:
            if literal in core_literals or literal in FRONTEND_ONLY:
                continue
            mapping.setdefault(literal, pack)
    for pack, (all_literals, _key_literals) in pack_literals.items():
        for literal in all_literals:
            if literal in core_literals or literal in FRONTEND_ONLY:
                continue
            mapping.setdefault(literal, pack)
    for literal in core_literals:
        mapping.setdefault(literal, "")
    return mapping


# ------------------------------------------------- 前端节点按包名兜底推断

_GENERIC_TOKENS = {"comfyui", "comfy", "nodes", "node", "custom", "tools", "suite"}


def brand_tokens(pack: str) -> set[str]:
    """从包目录名里取出可识别的品牌词，例如 rgthree-comfy -> {rgthree}。"""
    return {
        tok for tok in re.split(r"[^a-z0-9]+", pack.lower())
        if len(tok) >= 6 and tok not in _GENERIC_TOKENS
    }


def infer_pack_by_name(node_type: str, packs: list[str]) -> str | None:
    """节点名里带包品牌词时（如 'Bookmark (rgthree)'）推断提供方。

    这类节点由该包的前端扩展注册，后端注册表里没有，只能靠名字认。
    """
    lowered = node_type.lower()
    hits = [p for p in packs if any(tok in lowered for tok in brand_tokens(p))]
    return hits[0] if len(hits) == 1 else None


# ---------------------------------------------------------------------- 主流程


def print_to_real(*args, **kwargs):
    """结果统一写到真实 stdout，避免被自定义节点的输出污染。"""
    kwargs.setdefault("file", REAL_STDOUT)
    kwargs.setdefault("flush", True)  # sys.stdout 已被替换，必须自己保证刷盘
    print(*args, **kwargs)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="从工作流文件推导 launch.sh 需要的 custom_nodes 白名单",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("workflows", nargs="+", help="工作流 JSON 文件路径（可多个）")
    parser.add_argument("--method", choices=("auto", "dynamic", "static"), default="auto",
                        help="auto=优先真实注册表，失败退回静态扫描（默认）")
    parser.add_argument("--json", action="store_true", help="输出 JSON")
    parser.add_argument("--write", metavar="FILE", help="把 WHITELIST_NODES 数组写入文件，供 launch.sh source")
    parser.add_argument("--verbose", "-v", action="store_true", help="打印每个节点由哪个包提供")
    args = parser.parse_args()

    missing_files = [w for w in args.workflows if not os.path.isfile(w)]
    if missing_files:
        for w in missing_files:
            print_to_real(f"找不到工作流文件：{w}", file=sys.stderr)
        return 2

    method = args.method
    mapping = None
    if method in ("auto", "dynamic"):
        ensure_venv_python()  # dynamic 需要用 ComfyUI 的 venv 才能导入依赖
    if method in ("auto", "dynamic"):
        mapping = build_index_dynamic()
        if mapping is None and method == "dynamic":
            return 1
    if mapping is None:
        method = "static"
        mapping = build_index_static()

    packs: set[str] = set()
    per_workflow: dict[str, dict[str, str]] = {}
    core: set[str] = set()
    frontend: set[str] = set()
    inferred: dict[str, str] = {}
    unknown: set[str] = set()

    all_packs = sorted(
        n for n in os.listdir(CUSTOM_NODES_DIR)
        if os.path.isdir(os.path.join(CUSTOM_NODES_DIR, n)) and not n.endswith(".disabled")
    )

    for workflow in args.workflows:
        detail: dict[str, str] = {}
        for node_type in sorted(collect_node_types(workflow)):
            pack = mapping.get(node_type)
            if pack:
                packs.add(pack)
                detail[node_type] = pack
            elif pack == "":
                core.add(node_type)
            elif node_type in FRONTEND_ONLY:
                frontend.add(node_type)
            else:
                guessed = infer_pack_by_name(node_type, all_packs)
                if guessed:
                    packs.add(guessed)
                    inferred[node_type] = guessed
                else:
                    unknown.add(node_type)
        per_workflow[workflow] = detail

    pack_list = sorted(packs)

    if args.json:
        print_to_real(json.dumps({
            "method": method,
            "packages": pack_list,
            "per_workflow": per_workflow,
            "core_nodes": sorted(core),
            "frontend_only": sorted(frontend),
            "inferred_by_name": inferred,
            "unknown": sorted(unknown),
        }, ensure_ascii=False, indent=2))
    else:
        print_to_real(f"映射方式：{method}")
        for workflow, detail in per_workflow.items():
            print_to_real(f"\n== {os.path.basename(workflow)}：{len(detail)} 个节点来自自定义包")
            if args.verbose:
                for node_type, pack in sorted(detail.items()):
                    print_to_real(f"   {node_type:46s} <- {pack}")
        print_to_real(f"\n== 需要加入白名单的包（{len(pack_list)} 个）")
        for pack in pack_list:
            print_to_real(f"   {pack}")
        if core:
            print_to_real(f"\n== 核心节点（无需白名单，共 {len(core)} 个）")
        if frontend:
            print_to_real(f"== 前端内置节点（无需白名单）：{', '.join(sorted(frontend))}")
        if inferred:
            print_to_real(f"\n== 由节点名里的包品牌词推断（这些是包的前端扩展注册的节点，{len(inferred)} 个）")
            for node_type, pack in sorted(inferred.items()):
                print_to_real(f"   {node_type}  -> {pack}")
        if unknown:
            print_to_real(f"\n== 未找到提供方（{len(unknown)} 个），核对是否缺包或名字有误")
            for node_type in sorted(unknown):
                print_to_real(f"   {node_type}")
        print_to_real("\n== 可直接粘进 launch.sh 的数组")
        print_to_real("WHITELIST_NODES=(")
        for pack in pack_list:
            print_to_real(f"    {pack}")
        print_to_real(")")

    if args.write:
        with open(args.write, "w", encoding="utf-8") as f:
            f.write("# 由 whitelist_from_workflow.py 生成，供 launch.sh source\n")
            f.write("# 重新生成：python whitelist_from_workflow.py <工作流...> --write whitelist_nodes.sh\n")
            f.write("WHITELIST_NODES=(\n")
            for pack in pack_list:
                f.write(f"    {pack}\n")
            f.write(")\n")
        print_to_real(f"已写入 {args.write}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
