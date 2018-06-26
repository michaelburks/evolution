# evolution

Evolves arithmetical functions towards a goal.

Mutations are performed in the following ways:
* perturbing values of constants
* inserting unary operations
* inserting binary operations with a random constant or 'x' input operand
* pruning operations and replacing them with a child function

Hyperparameters controlling generation size, mutation count, surivival conditions, and other factors are defined at the top of the 'train' function. Hyperparameters governing mutation are defined inline in the 'Function.mutate' function.
