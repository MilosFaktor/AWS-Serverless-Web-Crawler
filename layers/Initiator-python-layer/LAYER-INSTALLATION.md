# Lambda Layer: Python Dependencies for Initiator Function

This Lambda layer contains Python dependencies required for the Initiator Lambda function.  

**Note:**  
- Only `boto3` is included as an external dependency.  
- The `uuid` module was manually excluded because AWS Lambda already includes it in the standard Python runtime.

## Install Instructions

1. **Create the directory structure for your Lambda layer:**

mkdir -p initiator-layer/python/lib/python3.12/site-packages

2. **Move into the site-packages directory:**
cd initiator-layer/python/lib/python3.12/site-packages

3. **Install the dependencies listed in requirements.txt:**
pip3.12 install -r /path/to/requirements.txt --target .

4. **Package the layer:**
cd ../../../../../
zip -r9 initiator-layer.zip python

5.  **Upload to AWS Lambda via S3:**
- Upload `initiator-layer.zip` to an S3 bucket in your AWS account:  
aws s3 cp initiator-layer.zip s3://your-bucket-name/layers/initiator-layer.zip

- Go to AWS Lambda > Layers in the AWS Console.

- Click Create layer.

- Name it initiator-dependencies-layer.

- Choose Upload from S3 and provide the S3 URL

- Set Runtime: Python 3.12.

- Attach this layer to your Initiator Lambda Function in Code > Layers and add the correct ARN of the layer.
(You can find the Layer ARN in the Lambda console after creating the layer, under “Versions.”)