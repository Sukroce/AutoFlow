# AutoFlow

## AutoFlow is an IoT + AI system designed to intelligently distribute vehicle volumes across available routes to minimize total travel time and avoid congestion.
## This repository contains all the main components of the AutoFlow system:

### Dataset: A synthetic dataset carefully generated using a structured workflow to ensure realistic road behavior, time-of-day variations, and seasonal effects.
- Calculating capacity: [here](Final%20Capacity.txt)
- Pre dataset-generation process: [here](./Baseline%20Data%20for%20Generating%20Datasets)
- Code for generating datasets: [here](dataset_generator_from_baseline_data.ipynb)
- Datasets: [here](./Datasets)

### Machine Learning Models: Linear Regression and Random Forest Regressor models for each road of the three system roads trained on the generated dataset.
- Models code and pkl files: [here](./Machine%20Learning%20Models)
- Jupyter code that runs predictions continously every 5 minutes: [here](predictions.ipynb)

### Flutter Application: The mobile application that serves as the user interface for AutoFlow and allows applying the rerouting algorithm.
- Application Code: [here](./Flutter%20Application)
- Application Apk: [here](App_Apk.md)
