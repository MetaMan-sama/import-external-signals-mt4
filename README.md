# Import External Signals — MQL4 Script

A MetaTrader 4 script that reads **structured trade signals from an external CSV file** using `FileOpen()` with `FILE_CSV | FILE_READ`, parses each row into symbol, order type, lot size, stop loss, and take profit fields via sequential `FileReadString()` and `FileReadDouble()` calls, validates the parsed data against symbol tradability via `SymbolInfoInteger(SYMBOL_SELECT)`, and dispatches `OrderSend()` for each valid row — enabling external systems, spreadsheets, or algorithmic pipelines to drive live MT4 trade execution through a flat-file interface.

---

## Overview

This script provides a practical bridge between external signal generation systems and MetaTrader 4's trade execution engine. Rather than requiring API integration, it uses the simplest possible inter-process communication mechanism — a shared CSV file — making it compatible with any system that can write a delimited text file: Python scripts, Excel VBA macros, web scrapers, external EAs writing to the sandbox, or manual signal sheets. Each row in the file encodes a complete trade instruction; the script reads them sequentially, validates each one, constructs the appropriate SL/TP price levels from the pip values using `MarketInfo(MODE_POINT)`, normalizes prices via `NormalizeDouble()`, and fires `OrderSend()`. The entire file is consumed in a single `OnStart()` pass and the file handle is closed cleanly on completion.

> **Note on file naming:** The internal script identifier is `ImportSignals.mq4`. The README documents the actual CSV-driven trade execution logic.

---

## Features

- **Sequential CSV parsing** — `FileOpen(FileName, FILE_CSV | FILE_READ, ";")` opens a semicolon-delimited file; per-row fields read via `FileReadString()` (symbol, order type integer), `FileReadDouble()` (lot size, stop loss pips, take profit pips) in strict field order
- **Symbol tradability validation** — `SymbolInfoInteger(symbol, SYMBOL_SELECT)` checks each parsed symbol is available in Market Watch; invalid symbols log a skip message and `continue` to the next row
- **Order type resolution** — `orderType == 0 ? OP_BUY : OP_SELL` ternary; validation gate rejects any row where `orderType != 0 && orderType != 1` with a descriptive log
- **Directional SL/TP price construction** — buy orders: `SL = price − stopLoss × Point`, `TP = price + takeProfit × Point`; sell orders: `SL = price + stopLoss × Point`, `TP = price − takeProfit × Point` — both normalized via `NormalizeDouble()` with `MODE_DIGITS`
- **`OrderSend()` full-parameter dispatch** — includes symbol, order type, lot size, normalized price, `Slippage`, SL, TP, `"Signal Trade"` comment, magic number `0`, expiry `0`, and `clrGreen` marker
- **Per-row error reporting** — success logs ticket number, symbol, and order type; failure logs `GetLastError()` code and symbol for each rejected row
- **File handle cleanup** — `FileClose(handle)` called unconditionally after loop exits; `Print("All signals processed.")` confirms completion

---

## How It Works

1. `FileOpen(FileName, FILE_CSV | FILE_READ, ";")` opens the signal file; aborts with a log on `handle < 0`
2. `while (!FileIsEnding(handle))` iterates each row: reads symbol, orderType, lotSize, stopLoss, takeProfit sequentially
3. Validation gates check: `symbol == ""`, `lotSize <= 0`, `orderType != 0 && orderType != 1`, `!SymbolInfoInteger(symbol, SYMBOL_SELECT)` — each causes a `continue`
4. Current Ask/Bid retrieved via `MarketInfo(symbol, MODE_ASK / MODE_BID)`; SL/TP computed directionally and normalized
5. `OrderSend()` dispatched; ticket logged on success, `GetLastError()` logged on failure
6. `FileClose(handle)` closes the file after all rows are processed

---

## Signal File Format

Semicolon-delimited CSV, one trade per row, placed in the MT4 Files sandbox:

```
EURUSD;0;0.1;50;100
GBPUSD;1;0.2;30;60
USDJPY;0;0.1;40;80
```

Fields: `Symbol ; OrderType (0=Buy, 1=Sell) ; LotSize ; StopLossPips ; TakeProfitPips`

> File path: `%APPDATA%\MetaQuotes\Terminal\<TerminalID>\MQL4\Files\signals.csv`

---

## Input Parameters

| Parameter   | Type   | Default        | Description                                          |
|-------------|--------|----------------|------------------------------------------------------|
| `FileName`  | string | `signals.csv`  | Name of the signal CSV file in the MT4 Files sandbox |
| `Slippage`  | int    | `3`            | Maximum allowed slippage in points per order         |

---

## Installation

1. Copy `Import_External_Signals_001.mq4` to `MQL4/Scripts/` in your MT4 data folder
2. Compile in MetaEditor (F7)
3. Place your signal CSV in the MT4 Files sandbox
4. Drag onto any chart from Navigator → Scripts; configure inputs and click **OK**

> **Warning:** This script places real orders immediately on execution. Always test on a **demo account** first with a known-good signal file.

---

## Requirements

- MetaTrader 4 (`#property strict` compatible build)
- MQL4 compiler (MetaEditor)
- Signal CSV file present in MT4 Files sandbox before script execution

---

## License

MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
