# DAppSCAN: từng nhãn audit so với kết quả mô hình

Dòng 'gốc' theo báo cáo audit; dòng 'flatten' là vị trí trong file eval/dappscan/flat/.

| Lỗ hổng | File | Báo cáo audit | Solidity | Hàm (audit) | Dòng gốc | Dòng flatten | Kết quả | Hàm mô hình gắn cờ | p hợp đồng |
|---|---|---|---|---|---|---|---|---|---|
| Timestamp dependency | 000_PriceHelper.sol | BlockSec-blocksec_alpaca_v1.0_signed | 0.8.10 | getTokenPrice | // SWC-116-Block values as a proxy for time | 795 | không dựng được đồ thị | - | - |
| Timestamp dependency | 008_LockupToken.sol | Chainsulting-DSLA Protocol-project1 | 0.4.24 | constructor | L24 | 89 | không dựng được đồ thị | - | - |
| Timestamp dependency | 011_wHakka.sol | Coinbae-Hakka_Finance_wHakka | 0.5.17 | stakingRateMax | L509 | 510 | phát hiện đúng hàm | stakingRateModel.stakingRateMax() L507-516 p=0.9712 | 0.5579 |
| Timestamp dependency | 011_wHakka.sol | Coinbae-Hakka_Finance_wHakka | 0.5.17 | unstake | L580 | 581 | phát hiện đúng hàm | wHakka.unstake(address,uint256,uint256) L578-595 p=0.9995 | 0.5579 |
| Timestamp dependency | 018_ChimVesting.sol | Hacken-Chimeras | >=0.6.0 <0.8.0 | checkLocks | L242 | 981 | không dựng được đồ thị | - | - |
| Timestamp dependency | 020_MateCore.sol | Hacken-Mate | >=0.8.0 | _canExecuteOrder | L86 | 1385 | không dựng được đồ thị | - | - |
| Timestamp dependency | 020_MateCore.sol | Hacken-Mate | >=0.8.0 | _executeOrder | L166 | 1465 | không dựng được đồ thị | - | - |
| Timestamp dependency | 020_MateCore.sol | Hacken-Mate | >=0.8.0 | _executeOrder | L225 | 1524 | không dựng được đồ thị | - | - |
| Timestamp dependency | 021_OrderBook.sol | Hacken-Mate | >=0.8.0 | placeOrder | L76 | 1043 | bỏ sót (hợp đồng có cờ, hàm không) | - | 0.9215 |
| Timestamp dependency | 021_OrderBook.sol | Hacken-Mate | >=0.8.0 | placeOrder | L105 | 1072 | bỏ sót (hợp đồng có cờ, hàm không) | - | 0.9215 |
| Timestamp dependency | 021_OrderBook.sol | Hacken-Mate | >=0.8.0 | cancelExpiredOrders | L145 | 1112 | phát hiện đúng hàm | OrderBook.cancelExpiredOrders(bytes32[]) L1107-1116 p=0.8993 | 0.9215 |
| Timestamp dependency | 022_UniswapHandler.sol | Hacken-Mate | >=0.8.0 | _swap | L38 | 796 | bỏ sót (hợp đồng có cờ, hàm không) | - | 0.8726 |
| Timestamp dependency | 024_StakingPlatform.sol | Hacken-Retreeb | =0.8.9 | startStaking | L58-L60 | 717-719 | không dựng được đồ thị | - | - |
| Timestamp dependency | 024_StakingPlatform.sol | Hacken-Retreeb | =0.8.9 | deposit | L72 | 731 | không dựng được đồ thị | - | - |
| Timestamp dependency | 024_StakingPlatform.sol | Hacken-Retreeb | =0.8.9 | deposit | L82 | 741 | không dựng được đồ thị | - | - |
| Timestamp dependency | 024_StakingPlatform.sol | Hacken-Retreeb | =0.8.9 | withdraw | L99 | 758 | không dựng được đồ thị | - | - |
| Timestamp dependency | 024_StakingPlatform.sol | Hacken-Retreeb | =0.8.9 | withdrawResidualBalance | L125 | 784 | không dựng được đồ thị | - | - |
| Timestamp dependency | 024_StakingPlatform.sol | Hacken-Retreeb | =0.8.9 | _percentageTimeRemaining | L214 | 873 | không dựng được đồ thị | - | - |
| Timestamp dependency | 024_StakingPlatform.sol | Hacken-Retreeb | =0.8.9 | _percentageTimeRemaining | L216-L217 | 875-876 | không dựng được đồ thị | - | - |
| Timestamp dependency | 024_StakingPlatform.sol | Hacken-Retreeb | =0.8.9 | _updateRewards | L250-L252 | 909-911 | không dựng được đồ thị | - | - |
| Timestamp dependency | 025_Staking.sol | Hacken-RichQUACK | 0.8.11 | startPool | L125 | 1626 | không dựng được đồ thị | - | - |
| Timestamp dependency | 025_Staking.sol | Hacken-RichQUACK | 0.8.11 | endPool | L134 | 1635 | không dựng được đồ thị | - | - |
| Timestamp dependency | 025_Staking.sol | Hacken-RichQUACK | 0.8.11 | deposit | L176 | 1677 | không dựng được đồ thị | - | - |
| Timestamp dependency | 026_SamuraiLegendsStaking.sol | Hacken-Samurai Legends | ^0.8.0 | N/A | L77 | 430 | dòng nằm ngoài mọi hàm | - | 0.4314 |
| Timestamp dependency | 026_SamuraiLegendsStaking.sol | Hacken-Samurai Legends | ^0.8.0 | lastTimeRewardActiveAt | L156 | 509 | hàm bị gắn cờ nhưng hợp đồng bị xếp không lỗi (bị ẩn) | SamuraiLegendsStaking.lastTimeRewardActiveAt() L506-509 p=0.5325 | 0.4314 |
| Timestamp dependency | 026_SamuraiLegendsStaking.sol | Hacken-Samurai Legends | ^0.8.0 | createPending | L251 | 604 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.4314 |
| Timestamp dependency | 026_SamuraiLegendsStaking.sol | Hacken-Samurai Legends | ^0.8.0 | getClaimablePendingPortion | L333 | 686 | hàm bị gắn cờ nhưng hợp đồng bị xếp không lỗi (bị ẩn) | SamuraiLegendsStaking.getClaimablePendingPortion(PendingAmount) L683-686 p=0.9973 | 0.4314 |
| Timestamp dependency | 026_SamuraiLegendsStaking.sol | Hacken-Samurai Legends | ^0.8.0 | addReward | L408 | 761 | hàm bị gắn cờ nhưng hợp đồng bị xếp không lỗi (bị ẩn) | SamuraiLegendsStaking.addReward(uint256) L755-775 p=0.6115 | 0.4314 |
| Timestamp dependency | 027_Staking.sol | Hacken-Talent Protocol | ^0.8.7 | adminWithdraw | L444 | 2982 | không dựng được đồ thị | - | - |
| Timestamp dependency | 027_Staking.sol | Hacken-Talent Protocol | ^0.8.7 | _checkpoint | L601 | 3139 | không dựng được đồ thị | - | - |
| Timestamp dependency | 027_Staking.sol | Hacken-Talent Protocol | ^0.8.7 | _updateS | L650-L651 | 3188-3189 | không dựng được đồ thị | - | - |
| Timestamp dependency | 027_Staking.sol | Hacken-Talent Protocol | ^0.8.7 | onlyWhileStakingEnabled | L748-L749 | 3286-3287 | không dựng được đồ thị | - | - |
| Timestamp dependency | 033_AMOCoinSale.sol | Iosiro-AMO Crowdsale Smart Contract Audi | ^0.4.18 | onlyValidPurchase | L132 | 733 | hàm bị gắn cờ nhưng hợp đồng bị xếp không lỗi (bị ẩn) | AMOCoinSale.onlyValidPurchase() L730-749 p=1.0 | 0.0979 |
| Timestamp dependency | 033_AMOCoinSale.sol | Iosiro-AMO Crowdsale Smart Contract Audi | ^0.4.18 | startSale | L349 | 950 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.0979 |
| Timestamp dependency | 033_AMOCoinSale.sol | Iosiro-AMO Crowdsale Smart Contract Audi | ^0.4.18 | endSale | L358 | 959 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.0979 |
| Timestamp dependency | 034_Crowdfund.sol | Iosiro-Etherparty Smart Contract Audit | 0.4.24 | duringCrowdfund | L61、68、76、162、173、180 | 62-181 | không dựng được đồ thị | - | - |
| Timestamp dependency | 037_Crowdsale.sol | New_Alchemy_Security_Audit-The Abyss DAI | ^0.4.21 | isValidContribution | L148 | 787 | bỏ sót (hợp đồng có cờ, hàm không) | - | 0.9626 |
| Timestamp dependency | 076_Pool.sol | QuillAudits-Amplify Smart Contract | ^0.8.0 | getBlockTimestamp | L330 | 1435 | dòng nằm ngoài mọi hàm | - | 0.8305 |
| Timestamp dependency | 077_Vesting.sol | QuillAudits-Amplify Smart Contract (vest | 0.8.4 | getBlockTimestamp | L218 | 219 | không dựng được đồ thị | - | - |
| Timestamp dependency | 079_BsktLPPool.sol | QuillAudits-BasketCoin Smart Contract | ^0.5.0 | checkStart | L363 | 364 | bỏ sót (hợp đồng có cờ, hàm không) | - | 0.66 |
| Timestamp dependency | 080_Sliced.sol | QuillAudits-BitSliced Smart Contract | =0.8.12 | sendTokens | L72 | 787 | phát hiện đúng hàm | Sliced.sendTokens() L785-795 p=1.0 | 0.5445 |
| Timestamp dependency | 081_Bollystake.sol | QuillAudits-BollyStake Smart Contract (n | ^0.8.0 | relock_stake | L1022 | 1023 | phát hiện đúng hàm | Bollystake.relock.stake(uint256) L1012-1046 p=0.9847 | 0.8685 |
| Timestamp dependency | 084_BsktEthLPPool.sol | QuillAudits-BsktEthLPPool Smart Contract | 0.5.0 | updateReward | L400, L417 | 401, 418 | phát hiện đúng hàm | BsktEthLPPool.lastTimeRewardApplicable() L417-419 p=0.9961 | 0.5771 |
| Timestamp dependency | 086_CryptoBatz.sol | QuillAudits-CryptoBatz Smart Contract | ^0.8.8 | rollStartIndex | L355 - L374 | 3822-3841 | không dựng được đồ thị | - | - |
| Timestamp dependency | 087_Fundum.sol | QuillAudits-Fundum Smart Contract | ^0.8.4 | swapTokensForETH | L351,369,388 | 352, 370, 389 | không dựng được đồ thị | - | - |
| Timestamp dependency | 095_LockletTokenVault.sol | QuillAudits-Locklet Smart Contract | ^0.8.0 | calculateClaim | L410 | 2399 | bỏ sót (hợp đồng có cờ, hàm không) | - | 0.7019 |
| Timestamp dependency | 095_LockletTokenVault.sol | QuillAudits-Locklet Smart Contract | ^0.8.0 | blockTime | 430 | 2419 | dòng nằm ngoài mọi hàm | - | 0.7019 |
| Timestamp dependency | 098_MainToken.sol | QuillAudits-NomadLand Smart Contract | ^0.4.23 | releaseOnce | L481 | 482 | hàm bị gắn cờ nhưng hợp đồng bị xếp không lỗi (bị ẩn) | FreezableToken.releaseOnce() L478-500 p=0.9919 | 0.0377 |
| Timestamp dependency | 098_MainToken.sol | QuillAudits-NomadLand Smart Contract | ^0.4.23 | releaseAll | L509 | 510 | hàm bị gắn cờ nhưng hợp đồng bị xếp không lỗi (bị ẩn) | FreezableToken.releaseAll() L506-515 p=0.7438 | 0.0377 |
| Timestamp dependency | 098_MainToken.sol | QuillAudits-NomadLand Smart Contract | ^0.4.23 | freeze | L526 | 527 | hàm bị gắn cờ nhưng hợp đồng bị xếp không lỗi (bị ẩn) | FreezableToken.freeze(address,uint64) L526-557 p=0.9355; FreezableMintableToken.freeze(address,uint64) L526-557 p=0.648 | 0.0377 |
| Timestamp dependency | 099_BasketFacet.sol | QuillAudits-PieDAO-ExperiPie | ^0.7.1 | calcOutStandingAnnualizedFee | L204 | 1085 | không dựng được đồ thị | - | - |
| Timestamp dependency | 099_BasketFacet.sol | QuillAudits-PieDAO-ExperiPie | ^0.7.1 | chargeOutstandingAnnualizedFee | L214 | 1095 | không dựng được đồ thị | - | - |
| Timestamp dependency | 100_VIDBToken.sol | QuillAudits-VIDB - v1.0 | ^0.5.0 | getLockedAmount | L722 | 723 | hàm bị gắn cờ nhưng hợp đồng bị xếp không lỗi (bị ẩn) | VIDBToken.getLockedAmount(address) L720-729 p=0.9079 | 0.1385 |
| Timestamp dependency | 118_MixinScheduler.sol | consensys-0x_v3_Staking | ^0.5.9 | _goToNextEpoch | L71 | 1783 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.4659 |
| Timestamp dependency | 127_PaymentStartStandardExit.sol | consensys-OmiseGo_MoreVP | 0.5.11 | setupStartStandardExitData | L124 | 2245 | không dựng được đồ thị | - | - |
| Timestamp dependency | 136_BAToken.sol | openzeppelin-Basic_Attention_Token | ^0.4.10 | N/A | L19-20 | 20-21 | không dựng được đồ thị | - | - |
| Timestamp dependency | 139_ProjectKudos.sol | openzeppelin-EtherCamp_ProjectKudos_publ | ^0.4.0 | onlyOwner | L331,332 | 332, 333 | bỏ sót (hợp đồng có cờ, hàm không) | - | 0.9946 |
| Timestamp dependency | 140_GovernorAlpha.sol | openzeppelin-Fei_Protocol | ^0.6.0 | votingPeriod | L24 | 26 | không dựng được đồ thị | - | - |
| Timestamp dependency | 141_GNTAllocation.sol | openzeppelin-Golem_Network_Token | ^0.4.4 | GNTAllocation | L22 | 239 | không dựng được đồ thị | - | - |
| Timestamp dependency | 142_Crowdsale.sol | openzeppelin-Hubii_Token | ^0.4.11 | isCrowdsale | L484,485 | 485, 486 | không dựng được đồ thị | - | - |
| Timestamp dependency | 145_ROSCA.sol | openzeppelin-WeTrust_ROSCA_contract_code | ^0.4.4 | ROSCA | L199 | 200 | bỏ sót (hợp đồng có cờ, hàm không) | - | 0.9884 |
| Timestamp dependency | 146_Crowdsale.sol | openzeppelin-iExec_RLC_Token | ^0.4.8 | minCapNotReached | L69 | 175 | không dựng được đồ thị | - | - |
| Timestamp dependency | 146_Crowdsale.sol | openzeppelin-iExec_RLC_Token | ^0.4.8 | - | L116、145、295 | 222-401 | không dựng được đồ thị | - | - |
| Timestamp dependency | 147_RLC.sol | openzeppelin-iExec_RLC_Token | ^0.4.8 | RLC | L37 | 38 | không dựng được đồ thị | - | - |
| Timestamp dependency | 147_RLC.sol | openzeppelin-iExec_RLC_Token | ^0.4.8 | unlock | L49 | 50 | không dựng được đồ thị | - | - |
| Reentrancy | 001_ImpossibleWrappedToken.sol | BlockSec-blocksec_impossible_finance_swa | =0.7.6 | deposit | L53-61 | 844-852 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.217 |
| Reentrancy | 001_ImpossibleWrappedToken.sol | BlockSec-blocksec_impossible_finance_swa | =0.7.6 | deposit | L65-73 | 856-864 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.217 |
| Reentrancy | 002_ve.sol | BlockSec-blocksec_multichain_vemult_v1.0 | 0.8.11 | withdraw | L1097-1104 | 1098-1105 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.22 |
| Reentrancy | 003_contract.sol | Callisto_Network-McAfeeDex Security Audi | ^0.4.9 | withdraw | L224 | 225 | phát hiện đúng hàm | SwitchDex.withdraw(uint256) L223-229 p=0.9992 | 0.8152 |
| Reentrancy | 004_CToken.sol | Chainsecurity-Compound  cToken unredacte | ^0.8.6 | _setComptroller | L930-947 | 1767-1784 | không dựng được đồ thị | - | - |
| Reentrancy | 005_Comptroller.sol | Chainsecurity-Compound  cToken unredacte | ^0.8.6 | liquidateBorrowAllowed | L465-501 | 3110-3146 | không dựng được đồ thị | - | - |
| Reentrancy | 006_TokensRelayer.sol | Chainsecurity-POA Network  OmniBridge | 0.7.5 | _relayTokens | L99-117 | 946-964 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1747 |
| Reentrancy | 007_ReferralFeeReceiver.sol | Chainsulting-1inch | ^0.6.0 | N/A | L11 | 2117 | không dựng được đồ thị | - | - |
| Reentrancy | 009_FountainBase.sol | Chainsulting-Furucombo-project2 | 0.6.12 | _depositAngel | L290-291 | 1949-1950 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.216 |
| Reentrancy | 009_FountainBase.sol | Chainsulting-Furucombo-project2 | 0.6.12 | _withdrawAngel | L295-L308 | 1954-1967 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.216 |
| Reentrancy | 010_CommunityVault.sol | Coinbae-Barnbridge_Vault | ^0.6.0 | setAllowance | L19 | 185 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.172 |
| Reentrancy | 011_wHakka.sol | Coinbae-Hakka_Finance_wHakka | 0.5.17 | stake | L556 - L573 | 557-574 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2274 |
| Reentrancy | 011_wHakka.sol | Coinbae-Hakka_Finance_wHakka | 0.5.17 | unstake | L576 - L592 | 577-593 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2274 |
| Reentrancy | 012_MasterChef.sol | Coinbae-Pud.Fi Masterchef_Audit | 0.6.7 | add | L105 - L127 | 1246-1268 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2112 |
| Reentrancy | 012_MasterChef.sol | Coinbae-Pud.Fi Masterchef_Audit | 0.6.7 | set | L131 - L143 | 1272-1284 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2112 |
| Reentrancy | 012_MasterChef.sol | Coinbae-Pud.Fi Masterchef_Audit | 0.6.7 | deposit | L227 - L266 | 1368-1407 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2112 |
| Reentrancy | 012_MasterChef.sol | Coinbae-Pud.Fi Masterchef_Audit | 0.6.7 | deposit | L247 - L251 | 1388-1392 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2112 |
| Reentrancy | 012_MasterChef.sol | Coinbae-Pud.Fi Masterchef_Audit | 0.6.7 | withdraw | L272 - L306 | 1413-1447 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2112 |
| Reentrancy | 012_MasterChef.sol | Coinbae-Pud.Fi Masterchef_Audit | 0.6.7 | emergencyWithdraw | L310 - L329 | 1451-1470 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2112 |
| Reentrancy | 012_MasterChef.sol | Coinbae-Pud.Fi Masterchef_Audit | 0.6.7 | balance | L378 - L381 | 1519-1522 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2112 |
| Reentrancy | 013_SpaceMonkey.sol | Coinbae-SpaceMonkey | ^0.8.4 | transfer | L53 - L64 | 446-457 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2793 |
| Reentrancy | 014_Etherscan-0x9F599410D207f3D2828a8712e5e543AC2E040382.sol | Coinbae-TapCoins_Token_Contract | ^0.4.11 | setUpgradeAgent | L373 - L394 | 374-395 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2928 |
| Reentrancy | 015_MintingFactoryV2.sol | Coinfabrik-MintingFactoryV2, BaseUpgrada | 0.8.4 | mintBatchEdition | L93 - L112 | 1239-1258 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2201 |
| Reentrancy | 016_woonklyPOS.sol | Coinfabrik-Woonkly Security Audit (DEX S | ^0.6.6 | processReward | L743 - L769 | 744-770 | không dựng được đồ thị | - | - |
| Reentrancy | 017_TempusController.sol | Coinspect-Tempus Audit | 0.8.6 | exitTempusAMMAndRedeem | L352-386 | 1366-1400 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1736 |
| Reentrancy | 017_TempusController.sol | Coinspect-Tempus Audit | 0.8.6 | completeExitAndRedeem | L395-436 | 1409-1450 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1736 |
| Reentrancy | 019_IDO.sol | Hacken-Ground Zero | ^0.8.4 | claim | L86 - L110 | 4908-4932 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1656 |
| Reentrancy | 023_PowerBombAvaxCurve.sol | Hacken-Powerbomb-V1 | 0.8.9 | claimReward | L269-293 | 2195-2219 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.245 |
| Reentrancy | 028_MasterChef.sol | ImmuneBytes-Bird Money(MasterChef)-Audit | 0.6.12 | deposit | L262 | 1206 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.3736 |
| Reentrancy | 028_MasterChef.sol | ImmuneBytes-Bird Money(MasterChef)-Audit | 0.6.12 | emergencyWithdraw | L311 | 1255 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.3736 |
| Reentrancy | 029_MasterChef.sol | ImmuneBytes-Bird Money-Final Audit Repor | 0.6.12 | deposit | L261-284 | 1205-1228 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.3736 |
| Reentrancy | 029_MasterChef.sol | ImmuneBytes-Bird Money-Final Audit Repor | 0.6.12 | withdraw | L287-306 | 1231-1250 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.3736 |
| Reentrancy | 030_MainWorkflow.sol | Inspex-SuperLauncher V.2 | 0.8.10 | _transferOut | L342 | 1422 | không dựng được đồ thị | - | - |
| Reentrancy | 031_Staking.sol | Inspex-Tokens, Farm & Shop | 0.8.11 | depositStable | L674 | 4744 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.3372 |
| Reentrancy | 032_BaseRewards.sol | Iosiro-1inch Exchange Staking Rewards Sm | ^0.6.12 | getReward | L75 | 271 | không dựng được đồ thị | - | - |
| Reentrancy | 035_SNXFlashLoanTool.sol | Iosiro-SNX FlashBurn Smart Contract Audi | ^0.7.6 | swap | L143 | 1343 | không dựng được đồ thị | - | - |
| Reentrancy | 036_Vester.sol | Iosiro-Synthetix Vest Tool Smart Contrac | ^0.8.0 | redeemWithTransfer | L51 - L58 | 1746-1753 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.267 |
| Reentrancy | 036_Vester.sol | Iosiro-Synthetix Vest Tool Smart Contrac | ^0.8.0 | mint | L128 - L132 | 1823-1827 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.267 |
| Reentrancy | 038_FlashLoanLogic.sol | PeckShield-AaveV3 | 0.8.7 | executeFlashLoanSimple | L182-L240 | 5096-5154 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2062 |
| Reentrancy | 039_Swap_Factory_Future.sol | PeckShield-Arche |  | Impl_Delivery | L360-L380 | 361-381 | không dựng được đồ thị | - | - |
| Reentrancy | 040_AToken.sol | PeckShield-Atlantis | ^0.5.16 | borrowFresh | L738-L802 | 1956-2020 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1936 |
| Reentrancy | 041_BankingNode.sol | PeckShield-BNPL | ^0.8.0 | unstake | L615-L637 | 2179-2201 | không dựng được đồ thị | - | - |
| Reentrancy | 042_MasterChef.sol | PeckShield-BabySwap | >=0.6.12 | withdraw | L249-L267 | 1717-1735 | không dựng được đồ thị | - | - |
| Reentrancy | 043_BufferBNBOptions.sol | PeckShield-Buffer | ^0.8.0 | create | L142-L189 | 3047-3094 | không dựng được đồ thị | - | - |
| Reentrancy | 044_code.sol | PeckShield-COIN98 | >=0.6.0 <0.8.0 | vote | L181 | 182 | không dựng được đồ thị | - | - |
| Reentrancy | 045_StakingProxyUniV3.sol | PeckShield-Convex_Frax | 0.8.10 | lockAdditional | L94-L113 | 1138-1157 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1945 |
| Reentrancy | 046_CryptoHeroesUniverse.sol | PeckShield-CryptoHeroes | ^0.6.12 | deposit | L175 - L203 | 1584-1612 | không dựng được đồ thị | - | - |
| Reentrancy | 047_SinglePool.sol | PeckShield-DSG | =0.6.12 | emergencyWithdraw | L202-L214 | 843-855 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2197 |
| Reentrancy | 048_SkyRewardPool.sol | PeckShield-DarkCrypto | 0.6.12 | withdraw | L217-L234 | 768-785 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2817 |
| Reentrancy | 049_code.sol | PeckShield-ERC20_FAT | 0.6.12 | _delegate | L1030 - L1040 | 1031-1041 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2539 |
| Reentrancy | 050_LCToken.sol | PeckShield-ERC20_LuckyChip | 0.6.12 | _delegate | L222-L232 | 1419-1429 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2555 |
| Reentrancy | 051_HegicPool.sol | PeckShield-Hegic(v8888) | 0.8.6 | provideFrom | L373 - L409 | 3552-3588 | không dựng được đồ thị | - | - |
| Reentrancy | 052_Holdefi.sol | PeckShield-Holdefi | 0.6.12 | repayBorrowInternal | L1292-L1344 | 1828-1880 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.216 |
| Reentrancy | 053_masterchef.sol | PeckShield-KaoyaSwap | 0.8.7 | deposit | L196 - L208 | 1734-1746 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2952 |
| Reentrancy | 054_MasterMilker.sol | PeckShield-MilkySwap | 0.6.12 | emergencyWithdraw | L237-L244 | 1723-1730 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.3137 |
| Reentrancy | 055_LPool.sol | PeckShield-OpenLeverage1.0 | 0.7.6 | borrowFresh | L845-L885 | 2362-2402 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2219 |
| Reentrancy | 056_PikaPerpV2.sol | PeckShield-PikaPerpV2 | ^0.8.0 | closePositionWithId | L402-459 | 2945-3002 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2275 |
| Reentrancy | 057_PMintBurn.sol | PeckShield-PlutosV1 | >=0.4.21 <0.6.0 | deposit | L48-L63 | 77-92 | không dựng được đồ thị | - | - |
| Reentrancy | 058_RToken.sol | PeckShield-Rikkei | ^0.5.16 | borrowFresh | L738-L802 | 1944-2008 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2019 |
| Reentrancy | 059_MasterShiba.sol | PeckShield-ShibaNova | 0.6.12 | withdraw | L339 - L341 | 1351-1353 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2005 |
| Reentrancy | 060_LPGauge.sol | PeckShield-StackerVC | ^0.6.11 | deposit | L75-L89 | 694-708 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.3158 |
| Reentrancy | 061_MasterChef.sol | PeckShield-SushiSwap | 0.6.12 | withdraw | L219-L230 | 1702-1713 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2994 |
| Reentrancy | 062_StakingV2.sol | PeckShield-TranchessV1.1 | >=0.6.10 <0.8.0 | deposit | L340-L359 | 1442-1461 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2119 |
| Reentrancy | 063_LiquidityStaking.sol | PeckShield-Tranchessv1.0 | >=0.6.10 <0.8.0 | deposit | L60-L69 | 474-483 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2001 |
| Reentrancy | 064_bVault.sol | PeckShield-btdotfinance | ^0.5.16 | deposit | L357-L375 | 358-376 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1962 |
| Reentrancy | 065_LighthouseLib.sol | PepperSec-Aira-Robonomic | ^0.4.24 | withdraw | L24 | 1193 | không dựng được đồ thị | - | - |
| Reentrancy | 066_RobotLiabilityLib.sol | PepperSec-Aira-Robonomic | ^0.4.24 | finalize | L104 | 1376 | không dựng được đồ thị | - | - |
| Reentrancy | 067_FeeCollector.sol | QuillAudits-1inch-Fee Collector | ^0.8.0 | updateRewardNonLP | L340 - L343 | 1393-1396 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2367 |
| Reentrancy | 068_FixedRateSwap.sol | QuillAudits-1inch-Fixed Rate Swap | 0.8.9 | depositFor | L137 | 1442 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1888 |
| Reentrancy | 068_FixedRateSwap.sol | QuillAudits-1inch-Fixed Rate Swap | 0.8.9 | _swap | L323 | 1628 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1888 |
| Reentrancy | 069_LimitOrderProtocol.sol | QuillAudits-1inch-Limit Order Protocol | ^0.7.6 | fillOrderTo | L28 - L346 | 1484-1802 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2023 |
| Reentrancy | 070_BaseParaSwapAdapter.sol | QuillAudits-AAVE-ParaSwap Adapter | 0.6.12 | _pullAToken | L79 | 1142 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2022 |
| Reentrancy | 071_BaseParaSwapSellAdapter.sol | QuillAudits-AAVE-ParaSwap Adapter | 0.6.12 | _sellOnParaSwap | L35 | 1402 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2127 |
| Reentrancy | 072_acyc.sol | QuillAudits-ACYC Token Smart Contracts | ^0.8.0 | _transfer | L331 | 1159 | dòng nằm ngoài mọi hàm | - | 0.2046 |
| Reentrancy | 073_AbyssEth2Depositor.sol | QuillAudits-Abyss Finance-Abyss Eth2 Dep | 0.6.11 | deposit | L82 | 511 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1804 |
| Reentrancy | 074_stakin_contract.sol | QuillAudits-Algovest | ^0.6.0 | AVSTokenDonation | L74 - L84 | 453-463 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1796 |
| Reentrancy | 075_MasterChef.sol | QuillAudits-Alium Finance Smart Contract | 0.6.12 | emergencyWithdraw | L163 - L171 | 210-218 | không dựng được đồ thị | - | - |
| Reentrancy | 078_BCubePublicSale.sol | QuillAudits-BCUBE Smart Contract | 0.5.17 | buyBcubeUsingUSDT | L264 - L278 | 1129-1143 | không dựng được đồ thị | - | - |
| Reentrancy | 082_ProfitSplitter.sol | QuillAudits-Bond Appetit-Bond Appetit | ^0.6.0 | _payToRecipients | L228 | 1798 | không dựng được đồ thị | - | - |
| Reentrancy | 083_ProfitSplitter.sol | QuillAudits-Bond Appetit-Bond Appetit | ^0.6.0 | _payToRecipients | L228 | 1798 | không dựng được đồ thị | - | - |
| Reentrancy | 084_BsktEthLPPool.sol | QuillAudits-BsktEthLPPool Smart Contract | 0.5.0 | exit | L459-462 | 460-463 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1773 |
| Reentrancy | 085_CCapableErc20.sol | QuillAudits-C.R.E.A.M. Finance-Flashloan | ^0.5.16 | gulp | L133 | 2640 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2086 |
| Reentrancy | 088_CurveV1.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | exchange | L49 - L85 | 5327-5363 | không dựng được đồ thị | - | - |
| Reentrancy | 089_UniswapV2.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | swapTokensForExactTokens | L56 | 5587 | không dựng được đồ thị | - | - |
| Reentrancy | 089_UniswapV2.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | swapExactTokensForTokens | L110 | 5641 | không dựng được đồ thị | - | - |
| Reentrancy | 090_UniswapV3.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | exactInputSingle | L52 | 5472 | không dựng được đồ thị | - | - |
| Reentrancy | 090_UniswapV3.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | exactInput | L106 | 5526 | không dựng được đồ thị | - | - |
| Reentrancy | 090_UniswapV3.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | exactOutputSingle | L153 | 5573 | không dựng được đồ thị | - | - |
| Reentrancy | 090_UniswapV3.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | exactOutputSingle | L154 | 5574 | không dựng được đồ thị | - | - |
| Reentrancy | 090_UniswapV3.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | exactOutput | L210 | 5630 | không dựng được đồ thị | - | - |
| Reentrancy | 091_YearnV2.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | _deposit | L78 | 5650 | không dựng được đồ thị | - | - |
| Reentrancy | 091_YearnV2.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | withdraw | L132 | 5704 | không dựng được đồ thị | - | - |
| Reentrancy | 092_WETHGateway.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | addLiquidityETH | L98 - L112 | 4089-4103 | không dựng được đồ thị | - | - |
| Reentrancy | 092_WETHGateway.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | removeLiquidityETH | L120 - L140 | 4111-4131 | không dựng được đồ thị | - | - |
| Reentrancy | 092_WETHGateway.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | openCreditAccountETH | L151 - L171 | 4142-4162 | không dựng được đồ thị | - | - |
| Reentrancy | 092_WETHGateway.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | repayCreditAccountETH | L179 - L199 | 4170-4190 | không dựng được đồ thị | - | - |
| Reentrancy | 093_PoolService.sol | QuillAudits-GearBox Protocol-GearBox Pro | ^0.7.4 | lendCreditAccount | L238 - L258 | 4654-4674 | không dựng được đồ thị | - | - |
| Reentrancy | 094_StakingRewardsV3-1.sol | QuillAudits-Keep3r.Network-Keep3r.Networ | 0.8.6 | deposit | L210 - L226 | 211-227 | không dựng được đồ thị | - | - |
| Reentrancy | 096_MiniDOGE.sol | QuillAudits-MiniDOGE Smart Contract | ^0.8.4 | transfer | L572-575,586-590 | 573-576, 587-591 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1922 |
| Reentrancy | 097_moonship.sol | QuillAudits-Moonship Smart Contract | >=0.6.8 | transfer | L995.1009 | 997-1011 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2312 |
| Reentrancy | 101_yWETH.sol | QuillAudits-Yearn Finance-Yearn Protocol | ^0.5.16 | depositETH | L90 - L104 | 109-123 | không dựng được đồ thị | - | - |
| Reentrancy | 101_yWETH.sol | QuillAudits-Yearn Finance-Yearn Protocol | ^0.5.16 | withdrawETH | L144 - L162 | 163-181 | không dựng được đồ thị | - | - |
| Reentrancy | 102_yToken.sol | QuillAudits-Yearn Finance-Yearn Vaults V | ^0.6.12 | withdrawETH | L187 | 1878 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1707 |
| Reentrancy | 103_Main.sol | QuillAudits-coalichain | ^0.4.21 | createBallot | L51 | 655 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2349 |
| Reentrancy | 104_YVaultAssetProxy.sol | Runtime_Vеrification-ElementFinance | ^0.8.0 | reserveDeposit | L49 - L80 | 542-573 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2059 |
| Reentrancy | 105_CoreVoting.sol | Runtime_Vеrification-Element_Finance_Gov | ^0.8.0 | execute | L238 - L277 | 313-352 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.185 |
| Reentrancy | 106_GnosisSafe.sol | Runtime_Vеrification-GnosisSafe | ^0.5.0 | execTransaction | L70 - L105 | 677-712 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1731 |
| Reentrancy | 107_StakefishERC721Wrapper.sol | Runtime_Vеrification-stakefish_ethereum_ | 0.8.4 | mintTo | L53-L71 | 720-738 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2049 |
| Reentrancy | 108_CFVault.sol | SlowMist-CFFv2 Smart Contract Security A | >=0.4.21 <0.6.0 | withdraw | L121 - L153 | 771-803 | không dựng được đồ thị | - | - |
| Reentrancy | 109_PRA.sol | SlowMist-ForTube2.0 Smart Contract Secur | >=0.6.0 | lock | L66 - L80 | 454-468 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.175 |
| Reentrancy | 110_OKLGTokenLocker.sol | Solidity_Finance-OKLG - Smart Contract | ^0.8.4 | withdrawLockedTokens | L126 | 775 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1779 |
| Reentrancy | 111_BorrowerOperations.sol | Trail_of_Bits-Liquity | 0.6.11 | _moveTokensAndETHfromAdjustment | L351 | 3096 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1427 |
| Reentrancy | 112_Liquidator.sol | Trail_of_Bits-MapleFinance | 0.8.7 | liquidatePortion | L41-L51 | 192-202 | không dựng được đồ thị | - | - |
| Reentrancy | 113_VaultCore.sol | Trail_of_Bits-OriginDollar | 0.5.11 | mintMultiple | L88 - L128 | 1856-1896 | không dựng được đồ thị | - | - |
| Reentrancy | 114_MarketOracle.sol | Trail_of_Bits-ampleforth | 0.4.24 | getPriceAnd24HourVolume | L34 - L60 | 253-279 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.172 |
| Reentrancy | 115_Hermez.sol | Trail_of_Bits-hermez | 0.6.12 | addToken | L642 - L664 | 1648-1670 | không dựng được đồ thị | - | - |
| Reentrancy | 116_MetaTransactionsFeature.sol | consensys-0x_Exchange_v4 | ^0.6.5 | refundsAttachedEth | L100-107 | 4050-4057 | không dựng được đồ thị | - | - |
| Reentrancy | 117_UniswapFeature.sol | consensys-0x_Exchange_v4 | ^0.6.5 | sellToUniswap | L203-206 | 944-947 | không dựng được đồ thị | - | - |
| Reentrancy | 119_LendingPool.sol | consensys-Aave_Protocol_V2 | ^0.6.8 | deposit | L92-119 | 5398-5425 | không dựng được đồ thị | - | - |
| Reentrancy | 120_Amp.sol | consensys-Amp | 0.6.9 | _transferByPartition | L1131-L1201 | 1844-1914 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2005 |
| Reentrancy | 121_TransactionManager.sol | consensys-Connext NXTP — Noncustodial Xc | 0.8.4 | removeLiquidity | L229 - L254 | 2364-2389 | không dựng được đồ thị | - | - |
| Reentrancy | 122_FLAaveV2.sol | consensys-DeFi_Saver | ^0.7.0 | executeOperation | L106-137 | 1910-1941 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1889 |
| Reentrancy | 123_Hypervisor.sol | consensys-Gamma | 0.7.6 | withdraw | L175-216 | 2642-2683 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2333 |
| Reentrancy | 124_UniProxy.sol | consensys-Gamma |  | deposit | L75-82 | 1173-1180 | không dựng được đồ thị | - | - |
| Reentrancy | 125_Exchange.sol | consensys-GrowthDeFi WHEAT | ^0.6.0 | convertFundsFromInput | L80-90 | 1137-1147 | không dựng được đồ thị | - | - |
| Reentrancy | 126_IdleCDO.sol | consensys-Idle_Finance | 0.8.4 | _deposit | L242-258 | 3686-3702 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1899 |
| Reentrancy | 128_Pod.sol | consensys-PoolTogether_Pods | >=0.7.0 <0.8.0 | depositTo | L275-282 | 2410-2417 | không dựng được đồ thị | - | - |
| Reentrancy | 129_TokenDrop.sol | consensys-PoolTogether_Pods | >=0.7.0 <0.8.0 | claim | L141-155 | 753-767 | không dựng được đồ thị | - | - |
| Reentrancy | 130_YearnV2YieldSource.sol | consensys-PoolTogether_Sushi_and_Yearn_V | 0.6.12 | supplyTokenTo | L118-L129 | 1810-1821 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.182 |
| Reentrancy | 131_LockableERC777.sol | consensys-Skale_Token | ^0.5.3 | _burn | L399-422 | 1061-1084 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2272 |
| Reentrancy | 132_SkaleBalances.sol | consensys-Skale_Token | ^0.5.3 | tokensReceived | L55-68 | 3468-3481 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2988 |
| Reentrancy | 133_EternalHeroesFactory.sol | consensys-Skyweaver | ^0.5.16 | _buy | L279-285 | 457-463 | không dựng được đồ thị | - | - |
| Reentrancy | 134_DynamicLiquidTokenConverter.sol | consensys-Zer0_zBanc | 0.6.12 | reduceWeight | L125-L130 | 1623-1628 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1815 |
| Reentrancy | 135_ARCToken.sol | openzeppelin-Arcade_City_token |  | buyRecipient | L231 | 232 | bỏ sót (hợp đồng có cờ, hàm không) | - | 0.7723 |
| Reentrancy | 137_Fundraiser.sol | openzeppelin-COSMOS_Fundraiser | ^0.4.7 | donate | L95 | 96 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.1728 |
| Reentrancy | 138_Fund.sol | openzeppelin-Endaoment | ^0.6.10 | finalizeGrant | L119-134 | 174-189 | không dựng được đồ thị | - | - |
| Reentrancy | 143_Controller.sol | openzeppelin-Opyn_Gamma_Protocol | =0.6.10 | _runActions | L451-L508 | 1558-1615 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.2879 |
| Reentrancy | 144_AdminImpl.sol | openzeppelin-Solo_Margin_Protocol | 0.5.4 | _setPriceOracle | L258-L275 | 2559-2576 | bỏ sót (hợp đồng bị xếp không lỗi) | - | 0.189 |
