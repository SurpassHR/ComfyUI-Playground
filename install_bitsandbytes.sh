git clone https://github.com/bitsandbytes-foundation/bitsandbytes.git
cd bitsandbytes

cmake -DCOMPUTE_BACKEND=cuda -S .
make

pip install .

cd .. && rm -rf bitsandbytes