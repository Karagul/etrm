#' Step Hedge Portfolio Insurance (SHPI)
#'
#' Implements SHPI strategy for commodity price risk management
#' @param q numeric value for quantity to be hedged, either positive (net buyer) or negative (net seller)
#' @param tdate date vector with trading days
#' @param f numeric futures price vector
#' @param daysleft integer with days left to contract expiry
#' @param tper numeric target price markup/down to the price on the first trading day
#' @param tcost numeric transaction costs pr unit
#' @param int TRUE/FALSE integer restriction on tradable volume
#' @return instance of the SHPI class
#' @export

shpi<-function(
  q,
  tdate,
  f,
  daysleft,
  tper = 0.1,
  tcost = 0,
  int = TRUE
  ){

  # validation of arguments

  # missing arguments
  if (missing(q))
    stop("No volume specified")

  if (missing(tdate))
    stop("No date vector specified")

  if (missing(f))
    stop("No price vector specified")

  # invalid arguments
  if (tcost < 0)
    stop("Transaction cost cannot be a negative number")

  if (tper == 0)
    stop("Target price percentage cannot be zero")

  if (q < 0 & tper > 0)
    stop("A seller cannot set target price above current market")

  if (q > 0 & tper < 0)
    stop("A buyer cannot set target price below current market")

  if (length(tdate) != length(f))
    stop("Date and price vectors must be of equal length")

  # define vectors
  pp<-vector(length(f),mode="numeric")         # portfolio price
  h<-vector(length(f),mode="numeric")          # hedge
  tr<-vector(length(f),mode="numeric")         # transaction
  hper<-vector(length(f),mode="numeric")       # hedge percentage
  exp<-vector(length(f),mode="numeric")        # exposed
  HP<-vector(length(f),mode="numeric")         # high/low portfolio price


  if (int==FALSE){
    # model without tradeable volume restrictions (int=FALSE)
    digits<-10
  } else {
    # model with smallest tradeable volume unit = 1 (int=TRUE)
    digits<-0
  }

  # expression definitions for positive q (net buyer) and negative q (net seller)
  if(q>0){
    test1<-expression(any(pp>HP)==TRUE)
    test2<-expression(which(pp>=HP))
  } else {
    test1<-expression(any(pp<HP)==TRUE)
    test2<-expression(which(pp<=HP))
  }

  # calculation of hedge, trades, exposed vol and portfolio price
  h <- round((cumsum(f/f))/daysleft*q,digits)     # initial hedging plan
  HP <-rep(f[1]*(1+tper),length(f))               # target price vector

  # t=1
  hper[1]<-h[1]/q
  tr[1]<-h[1]
  exp[1]<-q-h[1]
  pp[1]<-(tr[1]*(f[1]+sign(tr[1])*tcost)+exp[1]*f[1])/q

  # t=2,..,T
  for(i in 2:(length(f))){
    hper[i]<-h[i]/q
    tr[i]<-h[i]-h[i-1]
    exp[i]<-q-h[i]
    pp[i]<-(cumsum(tr[1:i]*(f[1:i]+sign(tr[1:i])*tcost))[i]+exp[i]*f[i])/q
  }
  if(eval(test1)){
    h[min(eval(test2)):length(h)]<-q
    for(i in 2:length(f)){
      hper[i] <- h[i]/q
      tr[i]<-h[i]-h[i-1]
      exp[i]<-q-h[i]
      pp[i]<-(cumsum(tr[1:i]*(f[1:i]+sign(tr[1:i])*tcost))[i]+exp[i]*f[i])/q
    }
  }

  # create an instance of the SHPI class
  out <- new("SHPI",
             Name="SHPI",
             Volume=q,
             TargetPrice=unique(HP),
             TransCost=tcost,
             TradeisInt=int,
             Results=data.frame(
               Date=tdate,
               Price=f,
               Traded=tr,
               Exposed=exp,
               Hedged=h,
               HedgeRate=hper,
               Target = HP,
               PortfPrice=pp
             )
  )

    # return SHPI object
  return(out)
}
