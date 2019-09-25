package io.nuls.rpc;

import io.nuls.Config;
import io.nuls.base.RPCUtil;
import io.nuls.base.data.Transaction;
import io.nuls.core.core.annotation.Autowired;
import io.nuls.core.core.annotation.Component;
import io.nuls.core.exception.NulsException;
import io.nuls.core.log.Log;
import io.nuls.core.rpc.info.Constants;
import io.nuls.core.rpc.model.ModuleE;
import io.nuls.rpc.vo.TxRegisterDetail;

import java.io.IOException;
import java.util.*;
import java.util.function.Function;

/**
 * @Author: zhoulijun
 * @Time: 2019-06-12 17:57
 * @Description: 功能描述
 */
@Component
public class TransactionTools implements CallRpc {

    @Autowired
    Config config;

    /**
     * 发起新交易
     */
    public Boolean newTx(Transaction tx) throws NulsException, IOException {
        Map<String, Object> params = new HashMap<>(2);
        params.put("chainId", config.getChainId());
        //byte[] txSerialized = tx.serialize();
       // String txSerialEncoded = RPCUtil.encode(txSerialized);
        //params.put("tx", txSerialEncoded);

        params.put("tx", RPCUtil.encode(tx.serialize()));
        //return callRpc(ModuleE.TX.abbr, "tx_newTx", params, res -> true);
        boolean localResult = callRpc(ModuleE.TX.abbr, "tx_newTx", params, res -> true);

        //return callRpc(ModuleE.TX.abbr, "tx_newTx", params, res -> true);
        return localResult;

    }

    /**
     * 向交易模块注册交易
     * Register transactions with the transaction module
     */
    public boolean registerTx(String moduleName,int... txTyps) {
        try {
            List<TxRegisterDetail> txRegisterDetailList = new ArrayList<>();
            Arrays.stream(txTyps).forEach(txType->{
                TxRegisterDetail detail = new TxRegisterDetail();
                detail.setSystemTx(false);
                detail.setTxType(txType);
                detail.setUnlockTx(false);
                detail.setVerifySignature(true);
                detail.setVerifyFee(true);
                txRegisterDetailList.add(detail);
            });
            //向交易管理模块注册交易
            Map<String, Object> params = new HashMap<>();
            params.put(Constants.VERSION_KEY_STR, "1.0");
            params.put(Constants.CHAIN_ID, config.getChainId());
            params.put("moduleCode", moduleName);
            params.put("list", txRegisterDetailList);
            params.put("delList",List.of());
            Boolean aBoolean = callRpc(ModuleE.TX.abbr, "tx_register", params, (Function<Map<String, Object>, Boolean>) res -> (Boolean) res.get("value"));
            return aBoolean;
        } catch (Exception e) {
            Log.error("", e);
        }
        return true;
    }

}
