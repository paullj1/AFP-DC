#!/usr/local/bin/python3

import sys
from svmutil import *

print(sys.version)
y, x = [1,-1], [{1:1, 3:1}, {1:-1,3:-1}]
prob  = svm_problem(y, x)
param = svm_parameter('-t 0 -c 4 -b 1')
m = svm_train(prob, param)

p_label, p_acc, p_val = svm_predict(y[1:], x[1:], m)

print('')
print('Label: ')
print(p_label)
print('Acc: ')
print(p_acc)
print('Val: ')
print(p_val)
