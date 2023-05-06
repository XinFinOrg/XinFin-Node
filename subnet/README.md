# Subnet
XDC subnet is a blockchain network tailored for private and consortium use cases. It is powered by XDC2.0, which is the core engine of XDC network and enables state-of-the-art security against Byzantine attacks with forensics, fast transaction confirmation, and low energy consumption. It is also designed to enable secure checkpointing to XDC mainnet, so that it can harness the security, finality, and accountability of mainnet.

For more information, see https://xinfinorg.github.io/xdc-subnet-docs/category/subnet-chain

## How to start your own XDC subnet
1. Copy the `.env.example` and name it to `.env`
2. Replace the environment variables in the `.env` with your own ones:
  - INSTANCE_NAME={{Name of the instance}}
  - SYNC_MODE={{ The sync mode, either "full" or "fast"}}
  - PRIVATE_KEY={{ Your private key}}
  - NETWORK_ID={{ Your network ID, if not provided, default to 102}}
  - BOOTNODES={{ Your bootnode address, or the address of other running subnet nodes. Seperated by ",". For example: enode://da90183ab23829bfbe1e83e24dca6d6119486d601ae6e5506f8870f2819d345e380626abc4c92b1ebd8ea7eee733ddf44a1ee66dc0af6a59e99d0a1763f36d40@66.94.121.151:30303,enode://162e09c682b42f85420191f9246155b3ecdd2aad51035cce94c864b968c7ba697d71d9776226483d598b64e8720285c6534040a994f9d9cf5826b74fb95aa624@66.94.121.151:30304 }}
  - LOG_LEVEL= {{Log level, from 1 to 5 where 1 produce least logs. default to 3 if not provided}}
3. Provide your own `genesis.json` file
  - Follow WIP if you do not have genesis file yet (Working in progress) OR use the "genesis.json.example" as an example
4. Run `docker-compose up`

### Restart from fresh?
If you have already ran the nodes before and would like to start from completely fresh, you will need to nuke the stored chain data first.
Run below before running all the necessary from "How to start your own XDC subnet" again.
```
rm -rf xdcchain
```