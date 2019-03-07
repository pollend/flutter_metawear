package com.gaitlab.fluttermetawear;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;

import com.mbientlab.metawear.MetaWearBoard;
import com.mbientlab.metawear.android.BtleService;

import bolts.Continuation;
import bolts.Task;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;

public class FlutterMetawearPlugin implements MethodChannel.MethodCallHandler,ServiceConnection, RequestPermissionsResultListener {
    private static final String TAG = "FlutterMetawearPlugin";
    public static final String NAMESPACE = "plugins.gaitlab.com/flutter_metawear";
    private static final int REQUEST_COARSE_LOCATION_PERMISSIONS = 1452;
    private BtleService.LocalBinder serviceBinder;
    private final BluetoothManager bluetoothManager;
    private final BluetoothAdapter bluetoothAdapter;
    private final PluginRegistry.Registrar registrar;

    private final MethodChannel channel;

//    private final MethodCall

    /**
     * Plugin registration.
     */
    public static void registerWith(PluginRegistry.Registrar registrar) {
        final FlutterMetawearPlugin instance = new FlutterMetawearPlugin(registrar);
        registrar.addRequestPermissionsResultListener(instance);
    }


    FlutterMetawearPlugin(PluginRegistry.Registrar registrar){
        this.registrar = registrar;
        registrar.activity().bindService(new Intent(registrar.context(),BtleService.class),this, Context.BIND_AUTO_CREATE);
        bluetoothManager = (BluetoothManager) registrar.activity().getSystemService(Context.BLUETOOTH_SERVICE);
        bluetoothAdapter = bluetoothManager.getAdapter();

        // configure channels
        this.channel = new MethodChannel(registrar.messenger(),NAMESPACE + "/metawear");

        // set the method callback
        this.channel.setMethodCallHandler(this);
    }

    @Override
    public void onServiceConnected(ComponentName name, IBinder service) {
        serviceBinder = (BtleService.LocalBinder) service;
    }

    @Override
    public void onServiceDisconnected(ComponentName name) {

    }

    @Override
    public bool onRequestPermissionsResult(int i, String[] strings, int[] ints) {
        return false;
    }

    @Override
    public void onMethodCall(MethodCall methodCall, final MethodChannel.Result result) {

        if(methodCall.method.equals("connect")){
            final String mac = (String) methodCall.argument("mac");
            BluetoothDevice device = bluetoothAdapter.getRemoteDevice(mac);
            final MetaWearBoard board = serviceBinder.getMetaWearBoard(device);
            board.connectAsync().continueWith(new Continuation<Void, Object>() {
                @Override
                public Object then(Task<Void> task) throws Exception {
                    if (task.isFaulted()) {
                        result.success(false);
                    } else {
                        new MethodChannel(registrar.messenger(),NAMESPACE + "/metawear/"+  board.getMacAddress()).setMethodCallHandler(new MetawearChannel(registrar,board));
                        result.success(true);
                    }
                    return null;
                }
            });

        }

    }

}
