# bondable
 An "optimized" debt issuance mechanism in Solidity

---------------------
```
 _                     _       _     _      
| |__   ___  _ __   __| | __ _| |__ | | ___ 
| '_ \ / _ \| '_ \ / _` |/ _` | '_ \| |/ _ \
| |_) | (_) | | | | (_| | (_| | |_) | |  __/
|_.__/ \___/|_| |_|\__,_|\__,_|_.__/|_|\___|
```
---------------------

In order to reduce the friction of launching and attracting liquidity to debt markets, borrowers/lenders can utilize bondable to issue, trade, and redeem arbitrary uncollateralized debt.

A when launching a debt market, the borrower simply specifies their bond issuance rate, and maximum debt capacity.

Lenders can then purchase newly issued zero-coupon bonds at the specified rate, or alternatively purchase them on an open YieldSpace AMM market.

Debt is uncollateralized and backed solely by reputation.

---------------------

These contracts have not been audited. Use at your own discretion. 

---------------------
