| Task | Target | Model | Val R2 | Test R2 | Test MAE | Test RMSE | Train s |
|---|---|---|---:|---:|---:|---:|---:|
| curve | log10(Id) | ann | 0.9993 | 0.9993 | 0.05685 | 0.08201 | 102.1 |
| curve | log10(Id) | lightgbm | 0.9906 | 0.9915 | 0.2104 | 0.2869 | 7.8 |
| curve | log10(Id) | random_forest | 0.9900 | 0.9885 | 0.2312 | 0.3349 | 259.5 |
| curve | log10(Id) | decision_tree | 0.9816 | 0.9789 | 0.3169 | 0.4529 | 3.1 |
| curve | log10(Id) | polynomial | 0.9602 | 0.9641 | 0.4721 | 0.5906 | 7.5 |
| fom | SSmin (mV/dec) | ann | 0.9703 | 0.9461 | 3.147 | 4.867 | 5.7 |
| fom | SSmin (mV/dec) | polynomial | 0.9643 | 0.9575 | 2.93 | 4.319 | 0.1 |
| fom | SSmin (mV/dec) | lightgbm | 0.9248 | 0.9052 | 4.685 | 6.454 | 0.5 |
| fom | SSmin (mV/dec) | random_forest | 0.8543 | 0.8129 | 6.509 | 9.067 | 4.9 |
| fom | SSmin (mV/dec) | decision_tree | 0.7336 | 0.6851 | 8.545 | 11.76 | 0.2 |
| fom | Vth (V) | ann | 0.9076 | 0.8753 | 0.05639 | 0.1067 | 3.9 |
| fom | Vth (V) | polynomial | 0.8864 | 0.8680 | 0.07133 | 0.1098 | 0.2 |
| fom | Vth (V) | lightgbm | 0.8740 | 0.8657 | 0.07545 | 0.1108 | 0.6 |
| fom | Vth (V) | random_forest | 0.8421 | 0.8075 | 0.08994 | 0.1326 | 6.4 |
| fom | Vth (V) | decision_tree | 0.7124 | 0.6596 | 0.1256 | 0.1764 | 0.2 |
| fom | log10(Ioff) | ann | 0.9925 | 0.9964 | 0.02792 | 0.03869 | 6.4 |
| fom | log10(Ioff) | polynomial | 0.9786 | 0.9969 | 0.02587 | 0.03559 | 0.8 |
| fom | log10(Ioff) | lightgbm | 0.9713 | 0.9929 | 0.04435 | 0.05414 | 0.6 |
| fom | log10(Ioff) | random_forest | 0.9294 | 0.9778 | 0.07398 | 0.09562 | 6.1 |
| fom | log10(Ioff) | decision_tree | 0.9146 | 0.9433 | 0.1205 | 0.1528 | 0.2 |
| fom | log10(Ion) | polynomial | 0.9891 | 0.9935 | 0.05301 | 0.07371 | 3.6 |
| fom | log10(Ion) | ann | 0.9846 | 0.9851 | 0.08086 | 0.1119 | 5.6 |
| fom | log10(Ion) | lightgbm | 0.9653 | 0.9666 | 0.1289 | 0.1673 | 0.6 |
| fom | log10(Ion) | random_forest | 0.9101 | 0.8926 | 0.2314 | 0.3 | 3.4 |
| fom | log10(Ion) | decision_tree | 0.8411 | 0.8060 | 0.3183 | 0.4032 | 0.2 |
| fom | log10(gm,max) | polynomial | 0.9889 | 0.9950 | 0.04176 | 0.05567 | 0.2 |
| fom | log10(gm,max) | ann | 0.9870 | 0.9878 | 0.06297 | 0.0868 | 6.2 |
| fom | log10(gm,max) | lightgbm | 0.9610 | 0.9709 | 0.1017 | 0.1343 | 0.5 |
| fom | log10(gm,max) | random_forest | 0.9174 | 0.9145 | 0.1762 | 0.2302 | 6.3 |
| fom | log10(gm,max) | decision_tree | 0.8336 | 0.8098 | 0.252 | 0.3432 | 0.2 |
