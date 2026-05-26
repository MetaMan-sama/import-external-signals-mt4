//+------------------------------------------------------------------+
//|                                           ImportSignals.mq4      |
//|          Script to Read Signals from a File and Place Trades     |
//+------------------------------------------------------------------+
#property strict

// Input parameters
input string FileName = "signals.csv";  // File name for the external signals file
input int Slippage = 3;                // Maximum allowed slippage in points

//+------------------------------------------------------------------+
//| Main Function                                                   |
//+------------------------------------------------------------------+
void OnStart()
{
   // Open the file for reading
   int handle = FileOpen(FileName, FILE_CSV | FILE_READ, ";");
   if (handle < 0) {
      Print("Failed to open file: ", FileName);
      return;
   }

   // Read and process each line in the file
   while (!FileIsEnding(handle)) {
      string symbol = FileReadString(handle);   // Symbol
      int orderType = FileReadInteger(handle);  // Order type (0=BUY, 1=SELL)
      double lotSize = FileReadDouble(handle);  // Lot size
      double stopLoss = FileReadDouble(handle); // Stop loss (in pips)
      double takeProfit = FileReadDouble(handle); // Take profit (in pips)

      // Validate data
      if (symbol == "" || lotSize <= 0 || (orderType != 0 && orderType != 1)) {
         Print("Invalid data in signals file. Skipping entry.");
         continue;
      }

      // Check if the symbol exists and can be traded
      if (!SymbolInfoInteger(symbol, SYMBOL_SELECT)) {
         Print("Symbol ", symbol, " does not exist or cannot be traded. Skipping entry.");
         continue;
      }

      // Retrieve market prices
      double price = (orderType == 0) ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);
      double stopLossPrice = (orderType == 0) ? price - stopLoss * Point : price + stopLoss * Point;
      double takeProfitPrice = (orderType == 0) ? price + takeProfit * Point : price - takeProfit * Point;

      // Send trade order
      int ticket = OrderSend(symbol, (orderType == 0 ? OP_BUY : OP_SELL), lotSize, price, Slippage, stopLossPrice, takeProfitPrice, "Signal Trade", 0, 0, clrGreen);
      if (ticket < 0) {
         Print("Error placing order for ", symbol, ": ", GetLastError());
      } else {
         Print("Successfully placed order. Ticket: ", ticket, ", Symbol: ", symbol, ", Type: ", (orderType == 0 ? "BUY" : "SELL"));
      }
   }

   // Close the file
   FileClose(handle);
   Print("All signals processed.");
}
