using BayesianDataFusion
using Base.Test

using DataFrames

# IndexedDF
X = IndexedDF(DataFrame(A=[2,2,3], B=[1,3,4], C=[0., -1., 0.5]), [4,4])
@test nnz(X) == 3
@test size(getData(X, 1, 1)) == (0,3)
@test size(getData(X, 1, 4)) == (0,3)

x12 = getData(X, 1, 2)
@test size(x12) == (2,3)
@test x12[:,1] == [2,2]
@test x12[:,2] == [1,3]
@test x12[:,3] == [0., -1.]

@test size(getData(X, 2, 2)) == (0,3)

# IndexedDF with tuple input
X2 = IndexedDF(DataFrame(A=[2,2,3], B=[1,3,4], C=[0., -1., 0.5]), (4,4))
@test size(X2) == (4,4)

# IndexedDF with plain DataFrame
X2a = IndexedDF(DataFrame(A=[2,2,3], B=[1,1,4], C=[0.4, -1, -9]))
@test size(X2a) == (3,4)

# testing removing rows
X3 = removeSamples(X2, [2])
@test nnz(X3) == 2
@test size(X3) == (4,4)
x12 = getData(X3, 1, 2)
@test size(x12) == (1,3)
@test size(x12,1) == getCount(X3, 1, 2)

# creating relation from DataFrame
a = DataFrame(A=[1,2,2,3], B=[1,3,1,4], v=[0.4, 1.0, -1.9, 1.4])
r = Relation(a, "a")
@test size(r) == (3,4)

r.F = [1.0 2.5; -1 -2; 0 1; 3 -3]
assignToTest!(r, [1, 4])
@test r.F == [-1.0 -2; 0 1]
@test r.test_F == [1.0 2.5; 3 -3]

# creating empty Entity
e1 = Entity("e1")

# testing RelationData from sparse matrix
Y  = sprand(15,10, 0.1)
rd = RelationData(Y, class_cut = 0.5)
assignToTest!(rd.relations[1], 2)
@test numTest(rd.relations[1]) == 2
@test length(rd.relations[1].test_label) == 2

# running the data
result = macau(rd, burnin = 10, psamples = 10, verbose = false)
@test size(result["predictions"],1) == 2

# testing pred_all
Yhat = pred_all(rd.relations[1])
@test size(Yhat) == (15, 10)
@test_approx_eq Yhat[2,3] (rd.entities[1].model.sample[2,:] * rd.entities[2].model.sample[3,:]')[1] + rd.relations[1].model.mean_value

# predict all
result1 = macau(rd, burnin = 10, psamples = 10, verbose = false, full_prediction = true)
@test size(result1["predictions_full"]) == (15, 10)
x1 = result1["predictions"][1, 1:2]
y1 = result1["predictions"][:pred][1]
@test_approx_eq result1["predictions_full"][x1[1], x1[2]] y1

# custom function on latent variables
f1(a) = length(a)
result2 = macau(rd, burnin = 5, psamples = 6, verbose = false, f = f1)
@test length(result2["f_output"]) == 6

# pred for training set
ytrain_hat = pred(rd.relations[1])
@test length(ytrain_hat) == numData(rd.relations[1])
row = rd.relations[1].data.df[1,1]
col = rd.relations[1].data.df[1,2]
y1 = sum(rd.entities[1].model.sample[row,:] .* rd.entities[2].model.sample[col,:]) + valueMean(rd.relations[1].data)
@test_approx_eq y1 ytrain_hat[1]

# alpha sampling
include("alpha_sampling.jl")
include("tensor.jl")
include("custom_rd.jl")
include("rel_feat.jl")
include("lambda_sampling.jl")
include("solver.jl")
