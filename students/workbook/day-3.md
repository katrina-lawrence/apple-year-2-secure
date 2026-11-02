
# Day 3 — Create ML and Text Classification

**Challenge:** Develop and evaluate an on-device machine learning model that classifies dental notes using Apple's Create ML framework. Investigate how data quality, model performance, and integration decisions affect the reliability and security of AI-enabled applications.

Use this workbook to document your data preparation, model development, evaluation, integration, and testing. Follow the Day 3 Activity Brief and Student Daily Technical Setup for technical instructions.

## Part 1 — Investigate the Data

Review the supplied training and testing datasets before beginning model development.

| Dataset | Purpose |
|---|---|
| `day3_student_unclean_training_1000_final.csv` | Training data requiring review and cleaning |
| `day3_dental_test_300_challenging.csv` | Independent testing and evaluation |

### 1. Dataset Exploration

Examine the structure and content of the training dataset.

**Number of records:**

**Input text column:**

**Classification label column:**

**Available classification categories:**

### 2. Data Quality Investigation

Identify potential issues that could affect model training or evaluation.

| Data Quality Issue | Example or Record Reference | Potential Impact |
|---|---|---|
| Missing or incomplete values | | |
| Incorrect or inconsistent labels | | |
| Duplicate or conflicting records | | |
| Formatting or text inconsistencies | | |
| Other observations | | |

### 3. Initial Analysis

Which data quality issues are most likely to affect classification performance?

**Your analysis:**

How might inconsistent labels influence the model's predictions?

**Your analysis:**

Why is it important to inspect training data before using it to build a machine learning model?

**Your analysis:**

## Part 2 — Data Cleaning and Preparation

Follow the supplied data-cleaning instructions and document the changes you make.

### 1. Cleaning Record

| Record or Issue | Problem Identified | Action Taken | Reason |
|---|---|---|---|
| | | | |
| | | | |
| | | | |
| | | | |
| | | | |
| | | | |

### 2. Data Preparation Summary

**Number of records reviewed:**

**Number of records modified:**

**Number of records removed, if applicable:**

**Final number of training records:**

### 3. Cleaning Decisions

Which data quality issue required the most judgment to resolve?

**Your response:**

Did you encounter any records where the correct classification was unclear? How did you handle them?

**Your response:**

What risks could arise from automatically cleaning or relabelling data without human review?

**Your response:**

## Part 3 — Model Training with Create ML

Use the prepared dataset to train a text classification model.

### 1. Model Configuration

Record the configuration used during training.

| Configuration | Your Selection |
|---|---|
| Model type | |
| Training dataset | |
| Input text column | |
| Target label column | |
| Training configuration or settings | |
| Model version or identifier | |

### 2. Training Observations

**Did the dataset import successfully?**

**Were any warnings or errors encountered?**

**What adjustments were necessary?**

### 3. Initial Model Results

Record the performance information available in Create ML.

| Metric | Result |
|---|---|
| Training accuracy | |
| Validation accuracy | |
| Other reported metrics | |
| Training observations | |

### 4. Interpretation

How would you interpret the difference between training and validation performance?

**Your analysis:**

What might unusually high training accuracy indicate?

**Your analysis:**

Why is training accuracy alone insufficient to determine whether the model is reliable?

**Your analysis:**

## Part 4 — Independent Model Evaluation

Evaluate your trained model using the supplied independent testing dataset.

### 1. Evaluation Results

| Metric | Result |
|---|---|
| Number of test records | |
| Overall test accuracy | |
| Correct predictions | |
| Incorrect predictions | |
| Other available evaluation metrics | |

### 2. Classification Performance

Record the results for each classification category.

| Classification Category | Correct Predictions | Incorrect Predictions | Observations |
|---|---|---|---|
| | | | |
| | | | |
| | | | |
| | | | |
| | | | |

### 3. Error Analysis

Select examples where the model produced an incorrect or unexpected classification.

| Test Record | Expected Classification | Predicted Classification | Possible Explanation |
|---|---|---|---|
| 1 | | | |
| 2 | | | |
| 3 | | | |
| 4 | | | |

### 4. Evaluate the Results

Which categories were most difficult for the model to distinguish?

**Your findings:**

Did you identify any patterns in the incorrect predictions?

**Your findings:**

How did the model perform on unfamiliar, ambiguous, or challenging text?

**Your findings:**

What additional data or improvements might increase the model's reliability?

**Your recommendations:**

## Part 5 — Model Improvement

Based on your evaluation results, identify opportunities to improve the model.

### 1. Improvement Plan

| Identified Issue | Proposed Improvement | Expected Impact |
|---|---|---|
| | | |
| | | |
| | | |
| | | |

### 2. Model Iteration

If you retrain or modify the model, record the results.

| Metric | Initial Model | Revised Model |
|---|---|---|
| Training accuracy | | |
| Validation accuracy | | |
| Test accuracy | | |
| Key observations | | |

### 3. Analysis

What changes did you make?

**Your response:**

Did the changes improve performance on the independent testing dataset?

**Your response:**

What trade-offs or limitations remain?

**Your response:**

If you did not retrain the model, explain which improvements you would prioritize and why.

**Your response:**

## Part 6 — Integrate the Model into the Application

Export the trained model and integrate it into the approved My Dental Companion application.

### 1. Implementation Record

| Component or File | Change Made | Purpose |
|---|---|---|
| | | |
| | | |
| | | |
| | | |

### 2. Integration Details

**Exported model filename:**

**Application component responsible for classification:**

**How input text is passed to the model:**

**How the prediction is returned or displayed:**

### 3. Application Testing

| Test Scenario | Expected Behaviour | Actual Behaviour | Result |
|---|---|---|---|
| Clear example of a known category | | | |
| Ambiguous input | | | |
| Empty or invalid input | | | |
| Unfamiliar terminology | | | |
| Repeated classification | | | |

### 4. Integration Analysis

What are the advantages of performing text classification directly on the device?

**Your analysis:**

What limitations remain even when the model operates locally?

**Your analysis:**

How should the application handle uncertain or potentially incorrect predictions?

**Your recommendation:**

## Part 7 — Responsible AI and Security Review

Consider the implications of using a text classification model in an application that processes dental information.

### 1. Risk Assessment

| Area | Potential Risk | Recommended Control |
|---|---|---|
| Training data quality | | |
| Incorrect classification | | |
| Sensitive information | | |
| Model updates | | |
| Human oversight | | |

### 2. Security and Reliability Considerations

How does on-device processing affect the application's privacy and data exposure risks?

**Your analysis:**

Could a malicious or unusual input influence the model's classification? What safeguards might help?

**Your analysis:**

How should the application communicate model uncertainty to the user?

**Your recommendation:**

Which decisions should require human review rather than relying exclusively on the model?

**Your recommendation:**

## Part 8 — Peer Review

Exchange your model results and implementation findings with another learner or team.

**Reviewer / Team:**

**Model performance observations:**

**Data quality concerns identified:**

**Integration or testing feedback:**

**Recommendations received:**

**Changes made or proposed following the review:**

## Part 9 — Reflection

How did data quality influence your model development process?

**Your response:**

What did independent testing reveal that was not apparent during training?

**Your response:**

What are the most important limitations of your classification model?

**Your response:**

How does integrating an on-device model change the application's architecture and security considerations?

**Your response:**

What additional validation would be necessary before deploying this model in a production application?

**Your response:**

## Evidence Checklist

- [ ] Initial dataset investigation documented
- [ ] Data-cleaning decisions recorded
- [ ] Model training configuration documented
- [ ] Training and validation results captured
- [ ] Independent testing completed
- [ ] Incorrect predictions investigated
- [ ] Model improvements considered or tested
- [ ] Model exported and integrated into the application
- [ ] Application testing documented
- [ ] Responsible AI and security review completed
- [ ] Peer review completed
- [ ] Final reflection completed

---

[Back to Daily Workbooks](README.md)
