//+------------------------------------------------------------------+
//|                                                practice8gold.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>

input double Lots = 0.1;
input double RetracementPercent = 0.5;
input double SlPercent = 0.5;
input int Magic = 12345;

input double TpPercent = 1.0;
input double TslPercent = 0.0;
input double TslTriggerPercent = 0.7;

input int TimeCloseHour = 22;
input int TimeCloseMin = 0;

input ENUM_TIMEFRAMES MaTimeframe = PERIOD_D1;
input int MaPeriods = 100;
input ENUM_MA_METHOD MaMethod = MODE_SMA;
input ENUM_APPLIED_PRICE MaAppPrice = PRICE_CLOSE;

/*
input ENUM_TIMEFRAMES RsiTimeframe = PERIOD_M1;
input int RsiPeriods = 14;
input ENUM_APPLIED_PRICE RsiAppPrice = PRICE_CLOSE;
input int RsiUpperLevel = 70;
input int RsiLowerLevel = 30;
*/

CTrade trade;
int handleMa;
//int handleRsi;
bool isPosOpen;

int OnInit()
  {
   trade.SetExpertMagicNumber(Magic);
   handleMa = iMA(_Symbol, MaTimeframe, MaPeriods, 0, MaMethod, MaAppPrice);
//   handleRsi = iRSI(_Symbol, RsiTimeframe, RsiPeriods, RsiAppPrice);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {

   }
void OnTick(){
   // Ensures everything is calculated for each new bar to speed up backtesting
   int bars = iBars(_Symbol, PERIOD_M1);
   static int barsTotal = bars;
   if (barsTotal != bars){
      barsTotal = bars;
  
   double ma[];
   CopyBuffer(handleMa, MAIN_LINE, 1, 1, ma);
   
//   double rsi[];
//   CopyBuffer(handleRsi, MAIN_LINE, 1, 1, rsi);
   
   double close1 = iClose(_Symbol, MaTimeframe, 1);
   double high1 = iHigh(_Symbol, MaTimeframe, 1);
   double low1 = iLow(_Symbol, MaTimeframe, 1);
   
   double open0 = iOpen(_Symbol, MaTimeframe, 0);
   double close0 = iClose(_Symbol, MaTimeframe, 0);
   
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   MqlDateTime dt;
   TimeCurrent(dt);
   
   dt.hour = TimeCloseHour;
   dt.min = TimeCloseMin;
   dt.sec = 0;
   
   datetime timeClose = StructToTime(dt);
   
   for (int i = PositionsTotal()-1; i >= 0; i--){
      CPositionInfo pos;
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == Magic){
         isPosOpen = true;
         
         if(pos.PositionType() == POSITION_TYPE_BUY){
            if(bid > pos.PriceOpen() + pos.PriceOpen() * TslTriggerPercent /100){
               double sl = bid - bid * TslPercent / 100;
               
               if(sl > pos.StopLoss()){
                  trade.PositionModify(pos.Ticket(), sl, pos.TakeProfit());
               }
            }
         } else if (pos.PositionType() == POSITION_TYPE_SELL){
            if(ask < pos.PriceOpen() - pos.PriceOpen() * TslTriggerPercent / 100){
               double sl = ask + ask * TslPercent / 100;
               
               if (sl < pos.StopLoss() || pos.StopLoss() == 0){
                  trade.PositionModify(pos.Ticket(), sl, pos.TakeProfit());
               }
           }
         }
         
         if(TimeCurrent() >= timeClose){
            if(trade.PositionClose(pos.Ticket())){
               Print(__FUNCTION__, " > pos #", pos.Ticket()," was closed at closing time...");
            }
         }
      }
   }
   
   if (isPosOpen && TimeCurrent() > timeClose){
      Print(__FUNCTION__," > isPosOpen resetted...");
      isPosOpen = false;
   }
   
   if(!isPosOpen && TimeCurrent() < timeClose){
      if(close1 > ma[0]){
//         if(rsi[0] < RsiLowerLevel){
      
         if(close0 < open0 - RetracementPercent * open0 / 100){
            double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double sl = entry - entry * SlPercent / 100;
            double tp = entry + entry * TpPercent / 100;
            
            if(trade.Buy(Lots, _Symbol, entry, sl, tp)){
               isPosOpen = true;
            }
            Print(__FUNCTION__," > buy order sent...");
            }   
//         } 
   } else if (close1 < ma[0]){
//      if(rsi[0] > RsiUpperLevel){
      if(close0 > open0 + RetracementPercent * open0 / 100){
         double entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double sl = entry + entry * SlPercent / 100;
         double tp = entry - entry * TpPercent / 100;
         
         if (trade.Sell(Lots, _Symbol, entry, sl, tp)){
            isPosOpen = true;
            }
         Print(__FUNCTION__," > sell order sent...");
         }
//       }
      }
     }
   }
  }
//+------------------------------------------------------------------+
