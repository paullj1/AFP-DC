#!/usr/bin/python3

from sklearn import svm

n_samples = [0,0]
n_features = [1,1]
training_samples = [n_samples, n_features]
labels = [0,1]

clf = svm.SVC()
clf.fit(training_samples,labels)

print(clf.predict([[2.,2.]]))
print(clf.predict([[0.,0.]]))
