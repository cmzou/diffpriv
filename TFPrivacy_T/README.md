# Outline
`BankingNN.ipynb`: A notebook of my experiments with [TensorFlow Privacy](https://github.com/tensorflow/privacy) and [VisualizeNN](https://github.com/jzliu-100/visualize-neural-network)

`Interpretation.ipynb`: A notebook of my experiments with [LIME](https://github.com/marcotcr/lime)

`InterpretationScript.ipynb`: The streamlined version of `Interpretation.ipynb` setup to run on a compute cluster

## BankingNN
My goal of this notebook was to implement a testing framework that would allow people to implement a couple different optimizers and loss functions. There were some inherent limitations to this system however. In the current version, the model architecture is hardcoded and must remain the same for all runs. Additionally, this testing framework only measures accuracy. While this can be an effective testing method for many general applications, when checking fairness, testing only accuracy can have leave out the whole story. 

In it's current state, the framework is unable to output false positives and negatives, or true positives and negatives. Additionally, the framework is limited to only outputting metrics for the group as a whole rather than defined subgroups that researches may be interested such as race or sex. As a result, this framework was scrapped for the alternative found in `diffpriv/py_tf_yyz`.

## Interpretation
This notebook's purpose was to utilize LIME's framework of "explaining" model predictions and expand it to show how the features with the most impact might change between models. The purpose of this was the explore how the private models trained on the exact same data differed from non-private models.

## InterpretationScript
This is a simplified version of `Interpretatin.ipynb`
