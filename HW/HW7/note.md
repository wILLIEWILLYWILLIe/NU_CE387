# FFT SystemVerilog Debug 筆記

## 問題描述

所有 16 個 FFT 輸出樣本的 bit-accuracy 檢查全部失敗，需要與 C 參考程式 (`fft_quant.c`) 完全匹配。

---

## 修改檔案與修正內容

### 1. `my_fft_pkg.sv`

- 新增 `NUM_STAGES` 和 `INT_WIDTH = 32` 參數（匹配 C 的 32-bit `int`）
- 修正 4 個旋轉因子（Twiddle Factor），原本用雙精度計算，與 C 的 `float` 精度不同，差了 1：

| 旋轉因子 | 修正前 | 修正後 |
|----------|--------|--------|
| W^1 real | `0x3B21` | `0x3B20` |
| W^3 real | `0x187E` | `0x187D` |
| W^5 real | `0xE782` | `0xE783` |
| W^7 real | `0xC4DF` | `0xC4E0` |

---

### 2. `fft_stage.sv`（完全重寫）

**改動一：DIF → DIT 架構**
- 原本：DIF（先蝶形運算，後位元反轉）
- 修正：DIT（先位元反轉，後蝶形運算），匹配 C 程式
- 延遲線 `D = N/2^(s+1)` → `D = 2^s`
- DIF 是先 add/sub 再乘 twiddle → DIT 是先乘 twiddle 再 add/sub
- 新增 `delay_pipe` 對齊乘法器延遲

**改動二：移除 ÷2 縮放**
- 原本 `bf_add_r[DATA_WIDTH:1]`（右移 1 位 = ÷2），4 級疊加 = ÷16
- C 程式無此縮放，直接使用完整寬度結果

**改動三：資料寬度加寬**
- 內部信號從 16-bit → 32-bit，避免移除 ÷2 後溢位

---

### 3. `complex_mult.sv`（完全重寫）

**改動一：反量化順序**
- 原本：先加減再反量化 → `deq(a*b - c*d)`
- 修正：各乘積各自反量化再加減 → `deq(a*b) - deq(c*d)`，匹配 C 的 `DEQUANTIZE_I`

**改動二：反量化捨入方式**
- 原本用 `>>>` 算術右移（向下取整），C 用 `/`（向零截斷），負數結果不同
- 修正為使用 SV 有號除法 `/`

**修正後 Pipeline：**
```
Stage 1: 4 個乘積（a_r×w_r, a_i×w_i, a_r×w_i, a_i×w_r）
Stage 2: 各自反量化
Stage 3: 加減得最終複數結果
```

---

### 4. `fft_top.sv`（大幅重寫）

- 位元反轉從 FFT stages **之後** 移到 **之前**（DIT 架構）
- 級間信號從 16-bit 加寬至 32-bit
- 旋轉因子索引改為 DIT：stride = `N / 2^(s+1)`
- 最後輸出截斷回 16-bit（取低位元）

---

## 問題根因總結

| 問題 | 影響程度 | 修正方式 |
|------|---------|---------|
| ÷2 縮放 | 輸出約為期望值的 1/16 | 移除右移，加寬資料寬度至 32-bit |
| DIF vs DIT 架構 | 定點捨入點不同，bit-level 差異 | 改為 DIT 匹配 C 演算法 |
| 反量化順序 | bit-level 差異 | 改為每乘積各自反量化 |
| 反量化捨入 | 負數值差異 | `>>>` 改為 `/`（向零截斷） |
| 旋轉因子精度 | 特定樣本差 1 | 用 C `float` 精度重新計算 |

## 驗證結果

```
Output Sample #0 ~ #15: 全部 PASS (Bit-Accurate)
TEST PASSED (100%) — 16/16 samples
```
