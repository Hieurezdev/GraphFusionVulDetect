# DAppSCAN vs. deployed pipeline

Labels: audit findings (function + line) from DAppSCAN. An alert on a line no auditor flagged is not proven wrong.

## timestamp

| | |
|---|---|
| files | 36 |
| file_stage | {'no_graph': 19, 'functions_scored': 12, 'contract_cleared': 5} |
| labels | 65 |
| label_verdict | {'no_graph': 36, 'flagged': 6, 'missed': 8, 'contract_cleared': 13, 'line_outside_any_function': 2} |
| recall_all_labels | 0.092 |
| recall_where_functions_scored | 0.429 |
| alerts | 30 |
| alerts_in_labelled_file | 25 |
| alerts_matching_label | 7 |
| functions_scored | 1029 |

## reentrancy

| | |
|---|---|
| files | 114 |
| file_stage | {'functions_scored': 48, 'no_graph': 43, 'contract_cleared': 23} |
| labels | 138 |
| label_verdict | {'missed': 52, 'flagged': 8, 'no_graph': 53, 'contract_cleared': 24, 'line_outside_any_function': 1} |
| recall_all_labels | 0.058 |
| recall_where_functions_scored | 0.133 |
| alerts | 128 |
| alerts_in_labelled_file | 89 |
| alerts_matching_label | 10 |
| functions_scored | 7686 |

## Every label

| case | kind | pragma | audit function | audit lines | verdict | product functions |
|---|---|---|---|---|---|---|
| 000_PriceHelper | timestamp | 0.8.10 | getTokenPrice | // SWC-116-Block values as a proxy for time | no_graph |  |
| 001_ImpossibleWrappedToken | reentrancy | =0.7.6 | deposit | L53-61 | missed |  |
| 001_ImpossibleWrappedToken | reentrancy | =0.7.6 | deposit | L65-73 | missed |  |
| 002_ve | reentrancy | 0.8.11 | withdraw | L1097-1104 | flagged | ve.withdraw(uint256) L1080-1104 (99.31%) |
| 003_contract | reentrancy | ^0.4.9 | withdraw | L224 | missed |  |
| 004_CToken | reentrancy | ^0.8.6 | _setComptroller | L930-947 | no_graph |  |
| 005_Comptroller | reentrancy | ^0.8.6 | liquidateBorrowAllowed | L465-501 | no_graph |  |
| 006_TokensRelayer | reentrancy | 0.7.5 | _relayTokens | L99-117 | contract_cleared |  |
| 007_ReferralFeeReceiver | reentrancy | ^0.6.0 | N/A | L11 | no_graph |  |
| 008_LockupToken | timestamp | 0.4.24 | constructor | L24 | no_graph |  |
| 009_FountainBase | reentrancy | 0.6.12 | _depositAngel | L290-291 | contract_cleared |  |
| 009_FountainBase | reentrancy | 0.6.12 | _withdrawAngel | L295-L308 | contract_cleared |  |
| 010_CommunityVault | reentrancy | ^0.6.0 | setAllowance | L19 | contract_cleared |  |
| 011_wHakka | timestamp | 0.5.17 | stakingRateMax | L509 | flagged | stakingRateModel.stakingRateMax() L506-515 (97.12%) |
| 011_wHakka | reentrancy | 0.5.17 | stake | L556 - L573 | flagged | wHakka.stake(address,uint256,uint256) L557-574 (99.90%) |
| 011_wHakka | reentrancy | 0.5.17 | unstake | L576 - L592 | flagged | wHakka.unstake(address,uint256,uint256) L577-594 (99.95%) |
| 011_wHakka | timestamp | 0.5.17 | unstake | L580 | flagged | wHakka.unstake(address,uint256,uint256) L577-594 (99.95%) |
| 012_MasterChef | reentrancy | 0.6.7 | add | L105 - L127 | missed |  |
| 012_MasterChef | reentrancy | 0.6.7 | set | L131 - L143 | missed |  |
| 012_MasterChef | reentrancy | 0.6.7 | deposit | L227 - L266 | missed |  |
| 012_MasterChef | reentrancy | 0.6.7 | deposit | L247 - L251 | missed |  |
| 012_MasterChef | reentrancy | 0.6.7 | withdraw | L272 - L306 | missed |  |
| 012_MasterChef | reentrancy | 0.6.7 | emergencyWithdraw | L310 - L329 | missed |  |
| 012_MasterChef | reentrancy | 0.6.7 | balance | L378 - L381 | missed |  |
| 013_SpaceMonkey | reentrancy | ^0.8.4 | transfer | L53 - L64 | missed |  |
| 014_Etherscan-0x9F599410D207f3D2828a8712e5e543AC2E040382 | reentrancy | ^0.4.11 | setUpgradeAgent | L373 - L394 | missed |  |
| 015_MintingFactoryV2 | reentrancy | 0.8.4 | mintBatchEdition | L93 - L112 | missed |  |
| 016_woonklyPOS | reentrancy | ^0.6.6 | processReward | L743 - L769 | no_graph |  |
| 017_TempusController | reentrancy | 0.8.6 | exitTempusAMMAndRedeem | L352-386 | missed |  |
| 017_TempusController | reentrancy | 0.8.6 | completeExitAndRedeem | L395-436 | missed |  |
| 018_ChimVesting | timestamp | >=0.6.0 <0.8.0 | checkLocks | L242 | no_graph |  |
| 019_IDO | reentrancy | ^0.8.4 | claim | L86 - L110 | flagged | IDO.claim() L85-109 (99.96%) |
| 020_MateCore | timestamp | >=0.8.0 | _canExecuteOrder | L86 | no_graph |  |
| 020_MateCore | timestamp | >=0.8.0 | _executeOrder | L166 | no_graph |  |
| 020_MateCore | timestamp | >=0.8.0 | _executeOrder | L225 | no_graph |  |
| 021_OrderBook | timestamp | >=0.8.0 | placeOrder | L76 | missed |  |
| 021_OrderBook | timestamp | >=0.8.0 | placeOrder | L105 | missed |  |
| 021_OrderBook | timestamp | >=0.8.0 | cancelExpiredOrders | L145 | flagged | OrderBook.cancelExpiredOrders(bytes32[]) L140-149 (89.93%) |
| 022_UniswapHandler | timestamp | >=0.8.0 | _swap | L38 | missed |  |
| 023_PowerBombAvaxCurve | reentrancy | 0.8.9 | claimReward | L269-293 | missed |  |
| 024_StakingPlatform | timestamp | =0.8.9 | startStaking | L58-L60 | no_graph |  |
| 024_StakingPlatform | timestamp | =0.8.9 | deposit | L72 | no_graph |  |
| 024_StakingPlatform | timestamp | =0.8.9 | deposit | L82 | no_graph |  |
| 024_StakingPlatform | timestamp | =0.8.9 | withdraw | L99 | no_graph |  |
| 024_StakingPlatform | timestamp | =0.8.9 | withdrawResidualBalance | L125 | no_graph |  |
| 024_StakingPlatform | timestamp | =0.8.9 | _percentageTimeRemaining | L214 | no_graph |  |
| 024_StakingPlatform | timestamp | =0.8.9 | _percentageTimeRemaining | L216-L217 | no_graph |  |
| 024_StakingPlatform | timestamp | =0.8.9 | _updateRewards | L250-L252 | no_graph |  |
| 025_Staking | timestamp | 0.8.11 | startPool | L125 | no_graph |  |
| 025_Staking | timestamp | 0.8.11 | endPool | L134 | no_graph |  |
| 025_Staking | timestamp | 0.8.11 | deposit | L176 | no_graph |  |
| 026_SamuraiLegendsStaking | timestamp | ^0.8.0 | N/A | L77 | contract_cleared |  |
| 026_SamuraiLegendsStaking | timestamp | ^0.8.0 | lastTimeRewardActiveAt | L156 | contract_cleared |  |
| 026_SamuraiLegendsStaking | timestamp | ^0.8.0 | createPending | L251 | contract_cleared |  |
| 026_SamuraiLegendsStaking | timestamp | ^0.8.0 | getClaimablePendingPortion | L333 | contract_cleared |  |
| 026_SamuraiLegendsStaking | timestamp | ^0.8.0 | addReward | L408 | contract_cleared |  |
| 027_Staking | timestamp | ^0.8.7 | adminWithdraw | L444 | no_graph |  |
| 027_Staking | timestamp | ^0.8.7 | _checkpoint | L601 | no_graph |  |
| 027_Staking | timestamp | ^0.8.7 | _updateS | L650-L651 | no_graph |  |
| 027_Staking | timestamp | ^0.8.7 | onlyWhileStakingEnabled | L748-L749 | no_graph |  |
| 028_MasterChef | reentrancy | 0.6.12 | deposit | L262 | flagged | MasterChef.deposit(uint256,uint256) L260-283 (100.00%) |
| 028_MasterChef | reentrancy | 0.6.12 | emergencyWithdraw | L311 | missed |  |
| 029_MasterChef | reentrancy | 0.6.12 | deposit | L261-284 | flagged | MasterChef.deposit(uint256,uint256) L259-282 (100.00%) |
| 029_MasterChef | reentrancy | 0.6.12 | withdraw | L287-306 | flagged | MasterChef.withdraw(uint256,uint256) L285-304 (100.00%) |
| 030_MainWorkflow | reentrancy | 0.8.10 | _transferOut | L342 | no_graph |  |
| 031_Staking | reentrancy | 0.8.11 | depositStable | L674 | missed |  |
| 032_BaseRewards | reentrancy | ^0.6.12 | getReward | L75 | no_graph |  |
| 033_AMOCoinSale | timestamp | ^0.4.18 | onlyValidPurchase | L132 | contract_cleared |  |
| 033_AMOCoinSale | timestamp | ^0.4.18 | startSale | L349 | contract_cleared |  |
| 033_AMOCoinSale | timestamp | ^0.4.18 | endSale | L358 | contract_cleared |  |
| 034_Crowdfund | timestamp | 0.4.24 | duringCrowdfund | L61、68、76、162、173、180 | no_graph |  |
| 035_SNXFlashLoanTool | reentrancy | ^0.7.6 | swap | L143 | no_graph |  |
| 036_Vester | reentrancy | ^0.8.0 | redeemWithTransfer | L51 - L58 | missed |  |
| 036_Vester | reentrancy | ^0.8.0 | mint | L128 - L132 | missed |  |
| 037_Crowdsale | timestamp | ^0.4.21 | isValidContribution | L148 | missed |  |
| 038_FlashLoanLogic | reentrancy | 0.8.7 | executeFlashLoanSimple | L182-L240 | missed |  |
| 039_Swap_Factory_Future | reentrancy |  | Impl_Delivery | L360-L380 | no_graph |  |
| 040_AToken | reentrancy | ^0.5.16 | borrowFresh | L738-L802 | missed |  |
| 041_BankingNode | reentrancy | ^0.8.0 | unstake | L615-L637 | no_graph |  |
| 042_MasterChef | reentrancy | >=0.6.12 | withdraw | L249-L267 | no_graph |  |
| 043_BufferBNBOptions | reentrancy | ^0.8.0 | create | L142-L189 | no_graph |  |
| 044_code | reentrancy | >=0.6.0 <0.8.0 | vote | L181 | no_graph |  |
| 045_StakingProxyUniV3 | reentrancy | 0.8.10 | lockAdditional | L94-L113 | contract_cleared |  |
| 046_CryptoHeroesUniverse | reentrancy | ^0.6.12 | deposit | L175 - L203 | no_graph |  |
| 047_SinglePool | reentrancy | =0.6.12 | emergencyWithdraw | L202-L214 | contract_cleared |  |
| 048_SkyRewardPool | reentrancy | 0.6.12 | withdraw | L217-L234 | missed |  |
| 049_code | reentrancy | 0.6.12 | _delegate | L1030 - L1040 | contract_cleared |  |
| 050_LCToken | reentrancy | 0.6.12 | _delegate | L222-L232 | missed |  |
| 051_HegicPool | reentrancy | 0.8.6 | provideFrom | L373 - L409 | no_graph |  |
| 052_Holdefi | reentrancy | 0.6.12 | repayBorrowInternal | L1292-L1344 | missed |  |
| 053_masterchef | reentrancy | 0.8.7 | deposit | L196 - L208 | contract_cleared |  |
| 054_MasterMilker | reentrancy | 0.6.12 | emergencyWithdraw | L237-L244 | missed |  |
| 055_LPool | reentrancy | 0.7.6 | borrowFresh | L845-L885 | contract_cleared |  |
| 056_PikaPerpV2 | reentrancy | ^0.8.0 | closePositionWithId | L402-459 | missed |  |
| 057_PMintBurn | reentrancy | >=0.4.21 <0.6.0 | deposit | L48-L63 | no_graph |  |
| 058_RToken | reentrancy | ^0.5.16 | borrowFresh | L738-L802 | missed |  |
| 059_MasterShiba | reentrancy | 0.6.12 | withdraw | L339 - L341 | contract_cleared |  |
| 060_LPGauge | reentrancy | ^0.6.11 | deposit | L75-L89 | contract_cleared |  |
| 061_MasterChef | reentrancy | 0.6.12 | withdraw | L219-L230 | missed |  |
| 062_StakingV2 | reentrancy | >=0.6.10 <0.8.0 | deposit | L340-L359 | missed |  |
| 063_LiquidityStaking | reentrancy | >=0.6.10 <0.8.0 | deposit | L60-L69 | missed |  |
| 064_bVault | reentrancy | ^0.5.16 | deposit | L357-L375 | contract_cleared |  |
| 065_LighthouseLib | reentrancy | ^0.4.24 | withdraw | L24 | no_graph |  |
| 066_RobotLiabilityLib | reentrancy | ^0.4.24 | finalize | L104 | no_graph |  |
| 067_FeeCollector | reentrancy | ^0.8.0 | updateRewardNonLP | L340 - L343 | missed |  |
| 068_FixedRateSwap | reentrancy | 0.8.9 | depositFor | L137 | missed |  |
| 068_FixedRateSwap | reentrancy | 0.8.9 | _swap | L323 | missed |  |
| 069_LimitOrderProtocol | reentrancy | ^0.7.6 | fillOrderTo | L28 - L346 | flagged | LimitOrderProtocol.fillOrderRFQTo(LimitOrderProtocol.OrderRFQ,bytes,uint256,uint256,address) L193-246 (99.80%) |
| 070_BaseParaSwapAdapter | reentrancy | 0.6.12 | _pullAToken | L79 | contract_cleared |  |
| 071_BaseParaSwapSellAdapter | reentrancy | 0.6.12 | _sellOnParaSwap | L35 | contract_cleared |  |
| 072_acyc | reentrancy | ^0.8.0 | _transfer | L331 | line_outside_any_function |  |
| 073_AbyssEth2Depositor | reentrancy | 0.6.11 | deposit | L82 | contract_cleared |  |
| 074_stakin_contract | reentrancy | ^0.6.0 | AVSTokenDonation | L74 - L84 | missed |  |
| 075_MasterChef | reentrancy | 0.6.12 | emergencyWithdraw | L163 - L171 | no_graph |  |
| 076_Pool | timestamp | ^0.8.0 | getBlockTimestamp | L330 | line_outside_any_function |  |
| 077_Vesting | timestamp | 0.8.4 | getBlockTimestamp | L218 | no_graph |  |
| 078_BCubePublicSale | reentrancy | 0.5.17 | buyBcubeUsingUSDT | L264 - L278 | no_graph |  |
| 079_BsktLPPool | timestamp | ^0.5.0 | checkStart | L363 | missed |  |
| 080_Sliced | timestamp | =0.8.12 | sendTokens | L72 | flagged | Sliced.sendTokens() L70-80 (100.00%) |
| 081_Bollystake | timestamp | ^0.8.0 | relock_stake | L1022 | flagged | Bollystake.relock.stake(uint256) L1011-1045 (98.47%) |
| 082_ProfitSplitter | reentrancy | ^0.6.0 | _payToRecipients | L228 | no_graph |  |
| 083_ProfitSplitter | reentrancy | ^0.6.0 | _payToRecipients | L228 | no_graph |  |
| 084_BsktEthLPPool | timestamp | 0.5.0 | updateReward | L400, L417 | flagged | BsktEthLPPool.lastTimeRewardApplicable() L416-418 (99.61%) |
| 084_BsktEthLPPool | reentrancy | 0.5.0 | exit | L459-462 | missed |  |
| 085_CCapableErc20 | reentrancy | ^0.5.16 | gulp | L133 | missed |  |
| 086_CryptoBatz | timestamp | ^0.8.8 | rollStartIndex | L355 - L374 | no_graph |  |
| 087_Fundum | timestamp | ^0.8.4 | swapTokensForETH | L351,369,388 | no_graph |  |
| 088_CurveV1 | reentrancy | ^0.7.4 | exchange | L49 - L85 | no_graph |  |
| 089_UniswapV2 | reentrancy | ^0.7.4 | swapTokensForExactTokens | L56 | no_graph |  |
| 089_UniswapV2 | reentrancy | ^0.7.4 | swapExactTokensForTokens | L110 | no_graph |  |
| 090_UniswapV3 | reentrancy | ^0.7.4 | exactInputSingle | L52 | no_graph |  |
| 090_UniswapV3 | reentrancy | ^0.7.4 | exactInput | L106 | no_graph |  |
| 090_UniswapV3 | reentrancy | ^0.7.4 | exactOutputSingle | L153 | no_graph |  |
| 090_UniswapV3 | reentrancy | ^0.7.4 | exactOutputSingle | L154 | no_graph |  |
| 090_UniswapV3 | reentrancy | ^0.7.4 | exactOutput | L210 | no_graph |  |
| 091_YearnV2 | reentrancy | ^0.7.4 | _deposit | L78 | no_graph |  |
| 091_YearnV2 | reentrancy | ^0.7.4 | withdraw | L132 | no_graph |  |
| 092_WETHGateway | reentrancy | ^0.7.4 | addLiquidityETH | L98 - L112 | no_graph |  |
| 092_WETHGateway | reentrancy | ^0.7.4 | removeLiquidityETH | L120 - L140 | no_graph |  |
| 092_WETHGateway | reentrancy | ^0.7.4 | openCreditAccountETH | L151 - L171 | no_graph |  |
| 092_WETHGateway | reentrancy | ^0.7.4 | repayCreditAccountETH | L179 - L199 | no_graph |  |
| 093_PoolService | reentrancy | ^0.7.4 | lendCreditAccount | L238 - L258 | no_graph |  |
| 094_StakingRewardsV3-1 | reentrancy | 0.8.6 | deposit | L210 - L226 | no_graph |  |
| 095_LockletTokenVault | timestamp | ^0.8.0 | calculateClaim | L410 | missed |  |
| 095_LockletTokenVault | timestamp | ^0.8.0 | blockTime | 430 | line_outside_any_function |  |
| 096_MiniDOGE | reentrancy | ^0.8.4 | transfer | L572-575,586-590 | missed |  |
| 097_moonship | reentrancy | >=0.6.8 | transfer | L995.1009 | missed |  |
| 098_MainToken | timestamp | ^0.4.23 | releaseOnce | L481 | contract_cleared |  |
| 098_MainToken | timestamp | ^0.4.23 | releaseAll | L509 | contract_cleared |  |
| 098_MainToken | timestamp | ^0.4.23 | freeze | L526 | contract_cleared |  |
| 099_BasketFacet | timestamp | ^0.7.1 | calcOutStandingAnnualizedFee | L204 | no_graph |  |
| 099_BasketFacet | timestamp | ^0.7.1 | chargeOutstandingAnnualizedFee | L214 | no_graph |  |
| 100_VIDBToken | timestamp | ^0.5.0 | getLockedAmount | L722 | contract_cleared |  |
| 101_yWETH | reentrancy | ^0.5.16 | depositETH | L90 - L104 | no_graph |  |
| 101_yWETH | reentrancy | ^0.5.16 | withdrawETH | L144 - L162 | no_graph |  |
| 102_yToken | reentrancy | ^0.6.12 | withdrawETH | L187 | contract_cleared |  |
| 103_Main | reentrancy | ^0.4.21 | createBallot | L51 | missed |  |
| 104_YVaultAssetProxy | reentrancy | ^0.8.0 | reserveDeposit | L49 - L80 | missed |  |
| 105_CoreVoting | reentrancy | ^0.8.0 | execute | L238 - L277 | contract_cleared |  |
| 106_GnosisSafe | reentrancy | ^0.5.0 | execTransaction | L70 - L105 | missed |  |
| 107_StakefishERC721Wrapper | reentrancy | 0.8.4 | mintTo | L53-L71 | contract_cleared |  |
| 108_CFVault | reentrancy | >=0.4.21 <0.6.0 | withdraw | L121 - L153 | no_graph |  |
| 109_PRA | reentrancy | >=0.6.0 | lock | L66 - L80 | missed |  |
| 110_OKLGTokenLocker | reentrancy | ^0.8.4 | withdrawLockedTokens | L126 | contract_cleared |  |
| 111_BorrowerOperations | reentrancy | 0.6.11 | _moveTokensAndETHfromAdjustment | L351 | missed |  |
| 112_Liquidator | reentrancy | 0.8.7 | liquidatePortion | L41-L51 | no_graph |  |
| 113_VaultCore | reentrancy | 0.5.11 | mintMultiple | L88 - L128 | no_graph |  |
| 114_MarketOracle | reentrancy | 0.4.24 | getPriceAnd24HourVolume | L34 - L60 | contract_cleared |  |
| 115_Hermez | reentrancy | 0.6.12 | addToken | L642 - L664 | no_graph |  |
| 116_MetaTransactionsFeature | reentrancy | ^0.6.5 | refundsAttachedEth | L100-107 | no_graph |  |
| 117_UniswapFeature | reentrancy | ^0.6.5 | sellToUniswap | L203-206 | no_graph |  |
| 118_MixinScheduler | timestamp | ^0.5.9 | _goToNextEpoch | L71 | contract_cleared |  |
| 119_LendingPool | reentrancy | ^0.6.8 | deposit | L92-119 | no_graph |  |
| 120_Amp | reentrancy | 0.6.9 | _transferByPartition | L1131-L1201 | contract_cleared |  |
| 121_TransactionManager | reentrancy | 0.8.4 | removeLiquidity | L229 - L254 | no_graph |  |
| 122_FLAaveV2 | reentrancy | ^0.7.0 | executeOperation | L106-137 | missed |  |
| 123_Hypervisor | reentrancy | 0.7.6 | withdraw | L175-216 | missed |  |
| 124_UniProxy | reentrancy |  | deposit | L75-82 | no_graph |  |
| 125_Exchange | reentrancy | ^0.6.0 | convertFundsFromInput | L80-90 | no_graph |  |
| 126_IdleCDO | reentrancy | 0.8.4 | _deposit | L242-258 | missed |  |
| 127_PaymentStartStandardExit | timestamp | 0.5.11 | setupStartStandardExitData | L124 | no_graph |  |
| 128_Pod | reentrancy | >=0.7.0 <0.8.0 | depositTo | L275-282 | no_graph |  |
| 129_TokenDrop | reentrancy | >=0.7.0 <0.8.0 | claim | L141-155 | no_graph |  |
| 130_YearnV2YieldSource | reentrancy | 0.6.12 | supplyTokenTo | L118-L129 | contract_cleared |  |
| 131_LockableERC777 | reentrancy | ^0.5.3 | _burn | L399-422 | contract_cleared |  |
| 132_SkaleBalances | reentrancy | ^0.5.3 | tokensReceived | L55-68 | missed |  |
| 133_EternalHeroesFactory | reentrancy | ^0.5.16 | _buy | L279-285 | no_graph |  |
| 134_DynamicLiquidTokenConverter | reentrancy | 0.6.12 | reduceWeight | L125-L130 | contract_cleared |  |
| 135_ARCToken | reentrancy |  | buyRecipient | L231 | missed |  |
| 136_BAToken | timestamp | ^0.4.10 | N/A | L19-20 | no_graph |  |
| 137_Fundraiser | reentrancy | ^0.4.7 | donate | L95 | missed |  |
| 138_Fund | reentrancy | ^0.6.10 | finalizeGrant | L119-134 | no_graph |  |
| 139_ProjectKudos | timestamp | ^0.4.0 | onlyOwner | L331,332 | missed |  |
| 140_GovernorAlpha | timestamp | ^0.6.0 | votingPeriod | L24 | no_graph |  |
| 141_GNTAllocation | timestamp | ^0.4.4 | GNTAllocation | L22 | no_graph |  |
| 142_Crowdsale | timestamp | ^0.4.11 | isCrowdsale | L484,485 | no_graph |  |
| 143_Controller | reentrancy | =0.6.10 | _runActions | L451-L508 | missed |  |
| 144_AdminImpl | reentrancy | 0.5.4 | _setPriceOracle | L258-L275 | missed |  |
| 145_ROSCA | timestamp | ^0.4.4 | ROSCA | L199 | missed |  |
| 146_Crowdsale | timestamp | ^0.4.8 | minCapNotReached | L69 | no_graph |  |
| 146_Crowdsale | timestamp | ^0.4.8 |  | L116、145、295 | no_graph |  |
| 147_RLC | timestamp | ^0.4.8 | RLC | L37 | no_graph |  |
| 147_RLC | timestamp | ^0.4.8 | unlock | L49 | no_graph |  |
