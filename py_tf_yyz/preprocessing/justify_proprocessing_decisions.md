# Data Preprocessing Justifications

Dataset: HDMA-LAR data for North Carolina in 2017

- [ ] Q1: Is it necessary to transform numerical data?

Control: nc_clean_0.csv
- log/sqrt transformed
Experimental: nc_clean_no_trans.csv
- remove log/sqrt transformation

**No Privacy**

| Metrics                  | Data1                  | Data2                  |
|--------------------------|------------------------|------------------------|
| Accuracy mean            | 83.62980425357819      | 82.19795048236847      |
| Accuracy variance        | 0.020755595673804805   | 0.004343336769707662   |
| Epsilon mean             | 2315.490748789897      | 2315.490748789897      |
| Epsilon variance         | 2.0679515313825692e-25 | 2.0679515313825692e-25 |
| Overall Confusion Matrix | [[ 2133.7  7821.3][ 1298.7 44457.3]] | [[4.26000e+01 9.91240e+03][5.30000e+00 4.57507e+04]]                        |
| Sensibility mean         | 0.9716168371361134     | 0.9998841681965207     |
| Specificity mean         | 0.21433450527373182    | 0.004279256654947263   |
| Precision mean           | 0.8505439554789384     | 0.821922139932424      |
| FP:FN ratio              | 7.964968074267792      | 4306.194444444444      |
| Race DI                  | 0.8632989119830684     | 0.9958254469120258     |
| Ethnicity DI             | 0.9952323935638091     | 1.0004041825682704     |
| Sex DI                   | 0.956914020343248      | 0.9979766289161918     |


**With Privacy**

| Metrics                  | Data1                  | Data2                  |
|--------------------------|------------------------|------------------------|
| Accuracy mean            | 81.90141916275024      | 81.31428360939026      |
| Accuracy variance        | 0.6732051601616718     | 4.164515853034345      |
| Epsilon mean             | 2315.490748789897      | 2315.490748789897      |
| Epsilon variance         | 2.0679515313825692e-25 | 2.0679515313825692e-25 |
| Overall Confusion Matrix | [[ 1338.3  8616.7][ 1466.2 44289.8]] | [[ 1505.2  8449.8][ 1960.2 43795.8]]                        |
| Sensibility mean         | 0.9679561150450213     | 0.9571597167584578     |
| Specificity mean         | 0.1344349573078855     | 0.1512004018081366     |
| Precision mean           | 0.837782589723402      | 0.8389697375977192     |
| FP:FN ratio              | 47.17669818550953      | 10.169981414885061     |
| Race DI                  | 0.8851434178225119     | 0.9082214562996862     |
| Ethnicity DI             | 0.9664514325415989     | 1.0186164060632268     |
| Sex DI                   | 0.987395620659956      | 0.9345556840101518     |

- [ ] Q2: Is it necessary to normalize numerical data?

- [ ] Q3: Does binarization makes a difference?

- [ ] Q4: Is it safe to remove records of HOEPA loans?

- [ ] Q5: Can I delete rows with 'Information not provided...'?

- [ ] Q6: Can I delete rows with 'Not applicable'?

- [ ] Q7: Which variables matter?

- [ ] Q8: Should I use a balanced dataset?

Control: nc_clean_0.csv
- ≈ 78% Approval, 22% Denial
Experimental: nc_clean_no_trans.csv
- 50% Approval, 50% Denial

**No Privacy**

| Metrics                  | Data1                  | Data2                  |
|--------------------------|------------------------|------------------------|
| Accuracy mean            | 83.66408884525299      | 71.46703600883484      |
| Accuracy variance        | 0.006356520305317304   | 1.4212490544878165     |
| Epsilon mean             | 2315.490748789897      | 2315.490748789897      |
| Epsilon variance         | 2.0679515313825692e-25 | 2.0679515313825692e-25 |
| Overall Confusion Matrix | [[ 2312.3  7642.7][ 1458.2 44297.8]] | [[ 6966.7  2988.3][12907.7 32848.3]] |
| Sensibility mean         | 0.9681309555031035     | 0.7179014774018707     |
| Specificity mean         | 0.23227523857358112    | 0.6998191863385234     |
| Precision mean           | 0.8528926842242364     | 0.9166825266668253     |
| FP:FN ratio              | 5.490421591080908      | 0.23327914831962446    |
| Race DI                  | 0.8465355761836454     | 0.6878138502799654     |
| Ethnicity DI             | 0.998680140559401      | 0.964786897565282      |
| Sex DI                   | 0.9490256005514454     | 0.8847948642046901     |


**With Privacy**

| Metrics                  | Data1                  | Data2                  |
|--------------------------|------------------------|------------------------|
| Accuracy mean            | 82.38049864768982      | 67.25440263748169      |
| Accuracy variance        | 0.39521912922992897    | 55.420264248668616     |
| Epsilon mean             | 2315.490748789897      | 2315.490748789897      |
| Epsilon variance         | 2.0679515313825692e-25 | 2.0679515313825692e-25 |
| Overall Confusion Matrix | [[ 1785.4  8169.6][ 1646.4 44109.6]]                        | [[ 7033.8  2921.2][15321.7 30434.3]]                        |
| Sensibility mean         | 0.9640178337267244     | 0.6651433691756272     |
| Specificity mean         | 0.179347061778001      | 0.7065595178302362     |
| Precision mean           | 0.8441173042577532     | 0.9138926214989389     |
| FP:FN ratio              | 10.602023484667836     | 0.2203037626300964     |
| Race DI                  | 0.8562511833096357     | 0.6226722139365131     |
| Ethnicity DI             | 0.9904762549699224     | 0.9420663123220903     |
| Sex DI                   | 0.9807612968968499     | 0.8590553535478114     |

- [ ] Q9: Does feature engineering increase accuracy?

- [ ] Q10: Should I remove outliers?
