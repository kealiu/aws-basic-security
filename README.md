# aws-basic-security
basic aws security configuration for new account, which balance cost and security.

# usage

## install

```
pip install -r requirements.txt
```

## generate config

edit the `config.json`, with proper value,  and then run `python main.py`

## apply security setting

execute terraform in `global` and `regional` directory.

```
terraform init
terraform apply
```

