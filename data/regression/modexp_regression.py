import json
import numpy as np
from sklearn.linear_model import LinearRegression
from scipy.optimize import curve_fit
import matplotlib.pyplot as plt

# model definition
def exponential_model(x, a, b):
    return a * (2 ** x) + b

# Load the data from the json file
with open('../modexp.json', 'r') as file:
    data = json.load(file)

# Extract precompileModExpGas values and corresponding exponents (x-axis)
x_data_2048 = [int(row[0].split('^')[-1].strip(')')) for row in data['2048']]
y_data_2048 = [int(row[-1].split('^')[-1].strip(')')) for row in data['2048']]

x_data_3072 = [int(row[0].split('^')[-1].strip(')')) for row in data['3072']]
y_data_3072 = [int(row[-1].split('^')[-1].strip(')')) for row in data['3072']]

# Prepare the data for linear regression 
# Using logarithmic scale for the exponents
x_2048 = np.log2(np.array(x_data_2048))
y_2048 = np.array(y_data_2048)

x_3072 = np.log2(np.array(x_data_3072))
y_3072 = np.array(y_data_3072)


# use curve_fit for regression
initial_guess = [300, 30000]  # use proper estimated values
params_2048, params_covariance = curve_fit(exponential_model, x_2048, y_2048, p0=initial_guess)
initial_guess = [300, 30000]  # use proper estimated values
params_3072, params_covariance = curve_fit(exponential_model, x_3072, y_3072, p0=initial_guess)

# check regression parameters
print(f'2048:  {params_2048[0]} * (2 ** τ) + {params_2048[1]}')
print(f'3072:  {params_3072[0]} * (2 ** τ) + {params_3072[1]}')

# Plotting
fig, ax = plt.subplots(1, 2, figsize=(14, 6))

# x_data_2048 = np.array(x_data_2048)
x_range = np.linspace(x_2048.min(), x_2048.max(), 300)


# Plot for 2048-bit key
ax[0].scatter(x_2048, y_2048, color='blue', label='Actual Data')
y_pred_2048 = params_2048[0] * (2** x_range) + params_2048[1]
ax[0].plot(x_range, y_pred_2048, color='red', label='Regression Line')
ax[0].set_title('2048-bit Key Regression')
ax[0].set_xlabel('Log2 of Exponent')
ax[0].set_ylabel('precompileModExpGas')
ax[0].legend()

# Plot for 3072-bit key
ax[1].scatter(x_3072, y_3072, color='blue', label='Actual Data')
y_pred_3072 = params_3072[0] * (2** x_range) + params_3072[1]
ax[1].plot(x_range, y_pred_3072, color='red', label='Regression Line')
ax[1].set_title('3072-bit Key Regression')
ax[1].set_xlabel('Log2 of Exponent')
ax[1].legend()

plt.tight_layout()
plt.savefig('modexp_regression_test.png')
plt.show()

