
# Day 3

## Activity 1 — Training and Integrating a Dental Note Classifier

*Duration: 90 minutes*  
*Format: Hands-on technical challenge*  
*Application: My Dental Companion*  
*Tools: Apple Numbers, Create ML, Xcode, iPhone 18 Pro Simulator*  
*iOS starting branch: `Day-3-server`*  
*Backend starting branch: `main`*

## Activity Overview

Clean and train a dental-note text classifier using Apple Numbers and Create ML, integrate the trained model into the Dental Notes iOS application, and test it in the iPhone 18 Pro simulator.

This guide uses the `Day-3-server` branch of the iOS repository and the `main` branch of the backend repository.

---

## Part 1: Data Cleaning, Model Training, and Evaluation

### Step 1: Clean the Dataset in Apple Numbers

1. Open the provided uncleaned dental-note CSV in Apple Numbers.
2. Use the 30 data-cleaning keys provided in the exercise to identify and correct data-quality issues.
3. Verify that every note has a valid category from the five supported classes: **Follow-up, Appointment, Treatment, Insurance, and Billing**.
4. Check for missing text, duplicate examples, inconsistent labels, and unnecessary formatting.
5. Export the cleaned dataset as a CSV file using **File → Export To → CSV**.

**Note:** Keep an original copy of the dataset so you can compare it with your cleaned version.

### Step 2: Train the Classifier in Create ML

1. Open Create ML on your Mac.
2. Select **New Document** and choose the **Text Classification** template.
3. Create a new project and import your cleaned CSV as training data.
4. Select the column containing dental-note text and the column containing the category labels.
5. Configure validation and testing data according to the exercise instructions.
6. Click **Train** and wait for the training process to complete.

### Step 3: Evaluate Model Performance

Once your model has finished training in Create ML, review its evaluation results. These metrics help you understand how accurately your classifier predicts dental-note categories and where it may need improvement.

Start by reviewing the model's overall accuracy, which measures the proportion of notes classified correctly.

**Accuracy = Correct Predictions / Total Predictions**

However, accuracy alone does not tell us how well the model performs for each individual category. For example, a model might perform very well on Appointment notes but struggle to distinguish Insurance notes from Billing notes.

To evaluate individual categories, we can use three additional metrics: **precision, recall, and F1-score**.

**Precision:** Of all the notes the model predicted as belonging to a particular category, how many were actually in that category?

`Precision = TP / (TP + FP)`

**Recall:** Of all the notes that actually belonged to a particular category, how many did the model correctly identify?

`Recall = TP / (TP + FN)`

**F1-Score:** The harmonic mean of precision and recall, providing a single metric that balances both.

`F1 = 2 × (Precision × Recall) / (Precision + Recall)`

**Where:**

- **TP (True Positive):** The model correctly predicts a note belongs to the category.
- **FP (False Positive):** The model predicts a note belongs to the category, but it actually belongs to another category.
- **FN (False Negative):** The model fails to identify a note that actually belongs to the category.

A model with high precision makes relatively few false-positive predictions for that category. A model with high recall successfully identifies most of the notes that actually belong to that category. A high F1-score indicates strong performance across both metrics.

### Activity A: Compare Different Model Iterations

Train your classifier using different configurations in Create ML. For example, you may compare Maximum Entropy and Transfer Learning algorithms, or retrain your model after making improvements to the dataset.

After each training iteration, record the algorithm, overall test accuracy, and category-level precision, recall, and F1-scores.

Use the same held-out test dataset for each iteration to make your comparisons meaningful.

#### Model Iteration 1

**Algorithm:** __________________________

**Dataset or Configuration Changes:** __________________________

**Overall Test Accuracy:** __________

| Classification Category | Precision | Recall | F1-Score |
|---|---|---|---|
| Follow-up | | | |
| Appointment | | | |
| Treatment | | | |
| Insurance | | | |
| Billing | | | |

#### Model Iteration 2

**Algorithm:** __________________________

**Dataset or Configuration Changes:** __________________________

**Overall Test Accuracy:** __________

| Classification Category | Precision | Recall | F1-Score |
|---|---|---|---|
| Follow-up | | | |
| Appointment | | | |
| Treatment | | | |
| Insurance | | | |
| Billing | | | |

#### Model Iteration 3

**Algorithm:** __________________________

**Dataset or Configuration Changes:** __________________________

**Overall Test Accuracy:** __________

| Classification Category | Precision | Recall | F1-Score |
|---|---|---|---|
| Follow-up | | | |
| Appointment | | | |
| Treatment | | | |
| Insurance | | | |
| Billing | | | |

**Note:** If Create ML does not display a particular metric directly, use the confusion matrix to calculate it when the necessary counts are available.

### Activity B: Interpret Your Model's Performance

Using your recorded results, answer the following questions.

**Question 1:** Which model iteration achieved the highest overall accuracy? Did it also achieve the strongest precision, recall, and F1-scores across all five categories?

**Response:**

---

**Question 2:** Identify a category with high precision but relatively low recall. What does this tell you about the model's predictions for that category? What types of errors is it making?

**Response:**

---

**Question 3:** Identify a category with high recall but relatively low precision. What does this indicate about how the model is classifying notes?

**Response:**

---

**Question 4:** Which of the five dental-note categories achieved the lowest F1-score? Why might the model struggle with this category? Consider similarities between categories, ambiguous wording, and the quality of training examples.

**Response:**

---

**Question 5:** Compare the results across your different model iterations. Did changing the algorithm or training data improve performance consistently across all five categories, or did some categories improve while others performed worse?

**Response:**

---

**Question 6:** Imagine that the application uses your classifier to identify Follow-up notes requiring action from dental staff. Would precision or recall be particularly important for this category? Explain the consequences of false positives and false negatives.

**Response:**

---

**Question 7:** Based on your evaluation results, which model iteration would you select for integration into the Dental Notes application? Justify your decision using the evaluation metrics rather than overall accuracy alone.

**Response:**

---

### Step 4: Export the Trained Model

1. In Create ML, locate the trained model.
2. Export it as a `.mlmodel` file.
3. Save it somewhere accessible, such as your Desktop or Documents folder.
4. Rename it to:

   `Dental_Note_Classifier.mlmodel`

We will use this standardized filename in the Xcode integration steps.

---

## Part 2: Clone and Prepare the iOS Application

### Step 5: Clone the Day 3 Student Repository

The Dental Notes application has already been developed by Forward Security. It includes the interface for creating and saving notes, a **Classify Note** button, and a classification results screen.

However, the classifier initially returns hard-coded example scores. Your task is to connect your own trained Core ML model to this existing interface.


#### Open Terminal

1. Open the Terminal application on your Mac.
2. Navigate to your Documents folder:

```bash
cd ~/Documents
```

#### Clone the Student Branch

Run:

```bash
git clone --branch Day-3-server https://github.com/katrina-lawrence/apple-year-2-secure.git Day3-Student-Lab
```

This downloads the `Day-3-server` branch into a folder called `Day3-Student-Lab`.

Navigate into the project:

```bash
cd ~/Documents/Day3-Student-Lab
```

Confirm that you are on the correct branch:

```bash
git branch --show-current
```

**Expected output:**

```text
Day-3-server
```

#### Open the Xcode Project

Run:

```bash
open "Dental Notes.xcodeproj"
```

Xcode should open the Dental Notes project.

In the Project Navigator on the left, locate:

- `ContentView.swift`
- The `Models` folder, which currently contains a placeholder text file
- `BackendConfig.example.plist`

You will use these files in the next steps.

### Step 6: Add Your Trained Model to Xcode

#### Locate the Exported Model

Find the file you exported from Create ML:

`Dental_Note_Classifier.mlmodel`

#### Add the Model to the Project

1. Open the Dental Notes project in Xcode.
2. In the Project Navigator, locate the `Models` folder.
3. Drag `Dental_Note_Classifier.mlmodel` from Finder into the `Models` folder in Xcode.
4. If Xcode presents an import dialog, select **Copy items if needed** and ensure the Dental Notes application target is selected.
5. Click **Finish**.

**Note:** The placeholder `.txt` file can remain in the folder.

#### Verify That Xcode Recognizes the Model

1. Click `Dental_Note_Classifier.mlmodel` in the Project Navigator.
2. Xcode should display information about the model, including its inputs and outputs.
3. Check that the model accepts text input and produces a predicted category.

**Important:** Adding a model file to Xcode makes it available to the application, but it does not automatically connect the model to the **Classify Note** button. You must implement that connection in Swift.

---

## Part 3: Connect the Core ML Model to the Application

### Step 7: Implement the Classifier in ContentView.swift

Forward Security has provided a placeholder classification function. You will replace it with code that loads your model and performs predictions on dental notes.

#### Import the Required Frameworks

Open `ContentView.swift`.

At the top of the file, you will see:

```swift
import Foundation
import SwiftData
import SwiftUI
```

Add the Core ML and Natural Language frameworks:

```swift
import Foundation
import CoreML
import NaturalLanguage
import SwiftData
import SwiftUI
```

Core ML is responsible for loading the trained model. Natural Language provides the text-classification interface.

#### Locate the Existing Classification Function

In Xcode, press **Command + F** and search for:

```swift
private func classifyNote()
```

You should find the following function:

```swift
private func classifyNote() {
    // TODO(Learner):
    // 1. Drop the generated .mlmodel into the Models folder in Xcode.
    // 2. Replace the fake/mock classification function with real logic that loads the bundled model and runs prediction on the note text.
    // 3. Read the model output as label-probability pairs.
    // 4. Convert predictions into your app's display format (category + score list).
    pendingClassificationResult = generateClassificationStub(for: note.value)
}
```

Currently, this function calls `generateClassificationStub`, which always returns the same example predictions.

#### Replace the classifyNote() Function

Replace the existing `classifyNote()` function with:

```swift
private func classifyNote() {
    do {
        pendingClassificationResult = try classifyNoteWithModel(note.value)
    } catch {
        print("Classification error: \(error.localizedDescription)")
        pendingClassificationResult = nil
    }
}
```

This function attempts to classify the current note using your trained model.

If classification fails, it prints an error message in the Xcode console rather than displaying fake predictions.

#### Add the Real Model-Classification Function

Directly below `classifyNote()`, add the following function:

```swift
private func classifyNoteWithModel(
    _ noteText: String
) throws -> NoteClassificationResult {

    // Step 1: Locate the compiled model in the app bundle.
    guard let modelURL = Bundle.main.url(
        forResource: "Dental_Note_Classifier",
        withExtension: "mlmodelc"
    ) else {
        throw NSError(
            domain: "NoteClassification",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "Classifier model is not available in the app bundle."
            ]
        )
    }

    // Step 2: Load the Core ML model.
    let coreModel = try MLModel(
        contentsOf: modelURL,
        configuration: MLModelConfiguration()
    )

    // Step 3: Create a Natural Language classifier.
    let classifier = try NLModel(mlModel: coreModel)

    // Step 4: Obtain predicted labels and scores.
    let hypotheses = classifier.predictedLabelHypotheses(
        for: noteText,
        maximumCount: 64
    )

    // Step 5: Handle available classification output.
    let categoryScores: [String: Double]

    if !hypotheses.isEmpty {
        categoryScores = hypotheses
    } else if let predictedLabel = classifier.predictedLabel(
        for: noteText
    ) {
        categoryScores = [predictedLabel: 1.0]
    } else {
        throw NSError(
            domain: "NoteClassification",
            code: 2,
            userInfo: [
                NSLocalizedDescriptionKey:
                    "The model did not return a prediction."
            ]
        )
    }

    // Step 6: Convert predictions into the app's format.
    let scores = categoryScores.map { category, score in
        NoteCategoryScore(
            category: category,
            score: score
        )
    }

    return NoteClassificationResult(scores: scores)
}
```

This implementation follows the working approach used in the `Day-4-server` branch, adapted to the standardized student model filename.


#### Understand How the Classification Code Works

| Code Component | Purpose |
|---|---|
| `Bundle.main.url(...)` | Finds the compiled model included in the application |
| `MLModel(contentsOf:)` | Loads the trained Core ML model |
| `NLModel(mlModel:)` | Creates a text-classification interface |
| `predictedLabelHypotheses(...)` | Produces predicted categories and associated scores |
| `NoteCategoryScore(...)` | Converts the model output into the format expected by the UI |
| `NoteClassificationResult(...)` | Sends the predictions to the existing results screen |

The filename in `forResource:` must match the model filename, excluding its extension.

For example, if your model is called `Dental_Note_Classifier.mlmodel`, the corresponding resource name is `Dental_Note_Classifier`.

#### Remove the Mock Classifier

Find the existing function:

`private func generateClassificationStub(for noteText: String)`

Delete that entire function, including its hard-coded category scores.

**Important:** Do not delete `dismissClassificationResult()` or the `NoteClassificationResult` structure.

The app should now use your actual trained model instead of the mock classifier.

#### Build the Project

1. In Xcode, select **Product → Build**, or press **Command + B**.
2. If the build succeeds, Xcode should display **Build Succeeded**.

If you receive an error, check that:

- You added both `CoreML` and `NaturalLanguage` imports.
- Your model filename matches the filename in the Swift code.
- Your `.mlmodel` file is included in the Dental Notes application target.
- You removed the old mock function call.

At this point, the classifier is integrated into the application. The next step is to configure the backend so that you can log in and create notes.

---

## Part 4: Set Up and Run the Backend

### Step 8: Clone and Configure the Backend Repository

The Dental Notes application uses a local FastAPI backend for authentication and note storage.

The backend does not run the Core ML classifier. Classification is performed locally within the iOS application.

#### Clone the Backend Repository

1. Open a new Terminal window.
2. Navigate to Documents:

```bash
cd ~/Documents
```

Clone the backend's `main` branch:

```bash
git clone --branch main https://github.com/katrina-lawrence/apple-year-2-backend.git Day3-Backend
```

Navigate into the backend directory:

```bash
cd ~/Documents/Day3-Backend
```

#### Create the Python Environment

If `uv` is not already installed on your Mac, install it using the approved setup instructions provided for the course.

Create a virtual environment:

```bash
uv venv --python 3.12 .venv
```

Activate the environment:

```bash
source .venv/bin/activate
```

Install the backend dependencies:

```bash
uv pip install -e '.[dev]'
```

This prepares the Python environment and installs the dependencies required by the backend.

#### Create the Backend Environment File

Run:

```bash
cp .env.example .env
```

This creates a local configuration file based on the repository's example.

#### Start the Backend

Run:

```bash
uvicorn app.main:app --reload
```

Leave this Terminal window open while using the Dental Notes application.

The backend should start on port `8000`.

#### Verify That the Backend Is Running

Open another Terminal window and run:

```bash
curl -i http://127.0.0.1:8000/status
```

**Expected response:**

```http
HTTP/1.1 200 OK
```

```json
{"status":"ok"}
```

A `200 OK` response confirms that the backend is reachable.

---

## Part 5: Connect Xcode to the Backend

### Step 9: Configure BackendConfig.plist

Return to the Terminal window for your iOS project.

Navigate into the project directory:

```bash
cd ~/Documents/Day3-Student-Lab
```

Create a local backend configuration file:

```bash
cp "Dental Notes/BackendConfig.example.plist" "Dental Notes/BackendConfig.plist"
```

The example file is a template. The new `BackendConfig.plist` contains the actual configuration used by your application.

Update the backend address:

```bash
plutil -replace baseURL -string "http://127.0.0.1:8000" "Dental Notes/BackendConfig.plist"
```

Verify the configuration:

```bash
plutil -p "Dental Notes/BackendConfig.plist"
```

**Expected output:**

```text
"baseURL" => "http://127.0.0.1:8000"
```

This tells the iOS application to communicate with the FastAPI backend running on your Mac.

**Note:** You only need to create this file once for a given project clone.

---

## Part 6: Run and Test the Classifier in the iPhone Simulator

### Step 10: Launch the Application

1. Return to Xcode.
2. Select the **Dental Notes Server** scheme.
3. Select **iPhone 18 Pro** as the simulator.
4. Press **Command + R**, or click the **Run** button.
5. Wait for the application to build and launch.

The iPhone 18 Pro simulator should open and display the Dental Notes application.

### Step 11: Log In

1. If this is your first time using the application, create a test account using the registration screen.
2. Otherwise, log in using your existing test account.

After authentication, the application should display the **Notes** screen.

### Step 12: Create a Test Note

1. Tap the **+** button to create a new dental note.
2. Enter the following example:

> Patient underwent root canal therapy on the lower right molar. The procedure was completed successfully with no complications.

3. Tap **Save**.

The note should appear in the Notes list.

### Step 13: Classify the Note

1. Open the note you just created.
2. Scroll to the **Classify Note** button.
3. Tap **Classify Note**.
4. Review the classification results.

The app should display the predicted category and associated score, followed by the other category scores.

For this example, the expected category is **Treatment**, although the actual result will depend on your trained model.

### Step 14: Test All Five Categories

Create additional notes using the examples below.

| Dental Note | Expected Category |
|---|---|
| Patient called to reschedule their dental cleaning appointment to November 19 at 10:30 AM. | Appointment |
| Contact the patient next week to check whether swelling has improved following the tooth extraction. | Follow-up |
| Patient underwent root canal therapy on the lower right molar. | Treatment |
| Dental insurance requires pre-authorization before approving coverage for the crown procedure. | Insurance |
| Patient has an outstanding balance of $175 for their previous dental cleaning. | Billing |

For each note, compare the expected category with the model's prediction and examine the scores.

### Step 15: Test an Ambiguous Note

Try the following:

> Patient requires a dental crown and has requested an estimate of the treatment cost before scheduling the procedure.

This note contains information related to **Treatment, Billing, and Appointment**.

1. Observe which category receives the highest score and whether the remaining scores reflect the ambiguity.
2. Discuss how the training data and classification labels influence the model's decision.

### Step 16: Evaluate the Application Results

Compare your simulator predictions with the evaluation results you observed in Create ML.

Consider the following questions:

1. Did the model correctly classify each test note?
2. Which categories were easiest or most difficult to distinguish?
3. Were the prediction scores consistent with your expectations?
4. Did the model struggle with ambiguous notes?
5. What additional training examples could improve performance?

**Remember:** A high classification score does not guarantee that the prediction is correct.

---

## Part 7: Running the Application Again

After completing the initial setup, you do not need to clone the repositories or reinstall the dependencies every time.

For subsequent testing sessions, follow these steps.

### Step 17: Start the Backend

Open Terminal:

```bash
cd ~/Documents/Day3-Backend
source .venv/bin/activate
uvicorn app.main:app --reload
```

### Step 18: Open Xcode

Open a second Terminal window:

```bash
cd ~/Documents/Day3-Student-Lab
open "Dental Notes.xcodeproj"
```

### Step 19: Run the Application

Select the **Dental Notes Server** scheme and **iPhone 18 Pro** simulator, then press **Command + R**.

### Step 20: Test Your Classifier

Log in, create or open a dental note, and tap **Classify Note**.

To stop the backend after testing, return to its Terminal window and press **Control + C**.

---

## Final Student Checklist

**Lab Completion: 0 of 10 completed**

- [ ] I cleaned the dataset using the 30 provided cleaning keys in Apple Numbers.
- [ ] I trained and evaluated a text classifier in Create ML.
- [ ] I exported my model as `Dental_Note_Classifier.mlmodel`.
- [ ] I cloned the `Day-3-server` branch of the iOS repository.
- [ ] I added my trained model to the `Models` folder in Xcode.
- [ ] I replaced the mock classification logic with real Core ML inference.
- [ ] I cloned and started the backend from the `main` branch.
- [ ] I configured `BackendConfig.plist` to use port `8000`.
- [ ] I ran the app in the iPhone 18 Pro simulator.
- [ ] I tested notes across all five categories and reviewed the results.

### Expected Outcome

By the end of this lab, you should have a trained text-classification model running locally inside the Dental Notes iOS application, with predictions displayed in the iPhone simulator.
