# RISC-V judge toolchain

Debian 13 (trixie) 上に RISC-V Linux 向けクロス GCC（提出プログラム用）、QEMU user mode（提出の実行用）、Spike、Proxy Kernel (`pk`) をインストールするイメージです。Spike と `pk` のソースは Dockerfile のコミット ID に固定しています。`pk` のビルドに必要な bare-metal GCC と開発用パッケージはビルド段階だけに置きます。

```bash
docker build -t hccc-riscv-toolchain:local .
docker run --rm hccc-riscv-toolchain:local sh -c 'qemu-riscv64 --version && riscv64-linux-gnu-gcc --version && test -x /opt/riscv/bin/pk'
```

HCCC の `test_runner_riscv` のベースイメージとして使用します。HCCC_infra と同じ親ディレクトリに clone し、上記のタグでビルドすると `docker-compose.local.yaml` から使用できます。
ビルド環境に余裕がある場合は `--build-arg BUILD_JOBS=8` で並列数を増やせます。
