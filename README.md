# MiniUartLab — UART TX/RX Loopback (Vivado XSIM)

## 1. 项目简介
本项目实现了一个最小可用的 UART 收发链路（8N1），并在 Vivado 自带的 XSIM 中完成端到端 loopback 自检。

- **UART TX**：将 8-bit 字节转换为串行波形输出到 `tx`
- **UART RX**：从 `rx` 输入的串行波形中恢复 8-bit 字节输出 `data_out`
- **Loopback 测试**：在 testbench 中将 `rx = tx` 回连，验证发送与接收数据一致

当前版本聚焦于“可综合 RTL + 自检 testbench + 仿真 PASS”，未包含 FIFO/CSR/AXI-lite（可作为后续扩展）。

---

## 2. 功能特性
- UART 格式：**8N1**（1 start + 8 data + 1 stop，无 parity）
- 可参数化：
  - `CLK_FREQ_HZ`（默认 100MHz）
  - `BAUD`（默认 115200）
  - `DATA_BITS`（默认 8）
- RX 特性：
  - 异步输入 `rx` 使用双触发器同步
  - 检测 start 位下降沿后，使用 **半 bit + 整 bit** 的中点采样恢复数据
  - stop 位校验，错误时置 `frame_err`
- 验证：
  - loopback 端到端自检：发送多组字节（A5/00/FF/3C/12/7E），接收端逐字节对比
  - `rx_frame_err` 必须保持为 0，否则 testbench 直接 `$fatal`

---

## 3. 工程结构
MiniUartLab/
  rtl/
    baud_gen.sv      # 产生 bit 级节拍 baud_tick（每个 bit 1-cycle pulse）
    uart_tx.sv       # UART 发送机（8N1）
    uart_rx.sv       # UART 接收机（8N1，中点采样 + stop 校验）
    top_uart.sv      # 顶层：连接 baud_gen/uart_tx/uart_rx
    fifo_sync.sv     # (可选) 同步 FIFO，目前未集成到 top
  sim/
    tb_uart_tx.sv    # (可选) 仅验证 uart_tx 的 testbench
    tb_top_uart.sv   # 端到端 loopback 自检 testbench（推荐跑这个）
    
---

## 4. 顶层接口说明（top_uart）
`top_uart.sv` 暴露最小的流接口用于发送/接收：

- **TX 输入（valid/ready）**
  - `tx_valid` / `tx_data` / `tx_ready`
  - 当 `tx_ready=1` 且 `tx_valid=1` 时，TX 接收 1 字节并开始发送

- **RX 输出（valid pulse）**
  - `rx_valid` / `rx_data`
  - 当接收到完整字节且 stop 位正确时，`rx_valid` 拉高 1 个 clk 周期

- **错误标志**
  - `rx_frame_err`
  - stop 位错误时置 1（当前版本为粘性标志，后续可做 W1C 清除）

---

## 5. 如何运行仿真（Vivado XSIM）

### 方式 A：GUI
1. 打开 Vivado → Create Project（RTL Project）
2. Add Sources
   - Design Sources：添加 `rtl/*.sv`
   - Simulation Sources：添加 `sim/tb_top_uart.sv`
3. 在 **Simulation Sources** 中右键 `tb_top_uart` → **Set as Top**
4. Run Simulation → **Run Behavioral Simulation**
5. Transcript 中看到：
   - `TOP LOOPBACK TEST PASS`

### 方式 B：仿真窗口 Tcl（可选）
在仿真窗口 Tcl Console 输入：
run all

---

## 6. 已知限制 / 后续扩展
### 限制
- 当前为最小版本：未集成 FIFO、寄存器映射、AXI-lite
- `BAUD` 分频采用整除 `DIV = CLK_FREQ_HZ / BAUD`，存在极小误差（仿真/学习用途可接受）

### 建议扩展（工程化升级）
1. 集成 `fifo_sync`：TX/RX 各一组 FIFO，支持背压与突发数据
2. 增加 CSR（或 AXI4-Lite）寄存器映射：可配置 baud divisor、使能、状态/错误 W1C
3. 更强验证：
   - 随机长序列压力测试（上千字节）
   - 人为注入 stop 位错误，检查 `frame_err` 行为
   - 覆盖率统计（functional coverage）

---

## 7. 结果
- 端到端 loopback 在 Vivado XSIM 中通过自检：
  - `TOP LOOPBACK TEST PASS`