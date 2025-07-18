### Want the full build journey with errors, fixes, lessons, and AWS tweaks?  
👉 [BUILD-JOURNAL.md](docs/BUILD-JOURNAL.md)

# Lambda Layer: Python Dependencies for Initiator Function

This Lambda layer contains Python dependencies required for the Initiator Lambda function.  

**Note:**  
- Only `boto3` is included as an external dependency.  
- The `uuid` module was manually excluded because AWS Lambda already includes it in the standard Python runtime.

## Install Instructions

1. **Create the directory structure for your Lambda layer:**
``` bash
mkdir -p initiator-layer/python/lib/python3.12/site-packages
```

2. **Move into the site-packages directory:**
``` bash
cd initiator-layer/python/lib/python3.12/site-packages
```

3. **Install the dependencies listed in requirements.txt:**
``` bash
pip3.12 install -r /path/to/requirements.txt --target .
```

4. **Package the layer:**
``` bash
cd ../../../../../
zip -r9 initiator-layer.zip python
```

5.  **Upload to AWS Lambda via S3:**
- Upload `initiator-layer.zip` to an S3 bucket in your AWS account:  
``` bash
aws s3 cp initiator-layer.zip s3://your-bucket-name/layers/initiator-layer.zip
```

- Go to AWS Lambda > Layers in the AWS Console.

- Click Create layer.

- Name it initiator-dependencies-layer.

- Choose Upload from S3 and provide the S3 URL

- Set Runtime: Python 3.12.

- Attach this layer to your Initiator Lambda Function in Code > Layers and add the correct ARN of the layer.
(You can find the Layer ARN in the Lambda console after creating the layer, under “Versions.”)

### Want the full build journey with errors, fixes, lessons, and AWS tweaks?  
👉 [BUILD-JOURNAL.md](docs/BUILD-JOURNAL.md)

### 🎥 Demo Video
Watch the full crawler in action on LinkedIn:  
👉 [Watch Demo Video](https://www.linkedin.com/embed/feed/update/urn:li:ugcPost:7350978672381616128?collapsed=1)

### Do you want to see all screenshots from project? 
👉 [All screenshots](docs/screenshots/)

## 🧑‍💻 Author
👋 Milos Faktor 💼 [LinkedIn](https://www.linkedin.com/in/milos-faktor-78b429255/)