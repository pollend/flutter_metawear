package com.gaitlab.fluttermetawear;

import com.mbientlab.metawear.DeviceInformation;
import com.mbientlab.metawear.MetaWearBoard;
import com.mbientlab.metawear.Observer;
import com.mbientlab.metawear.Route;
import com.mbientlab.metawear.module.Accelerometer;
import com.mbientlab.metawear.module.Settings;

import java.util.HashMap;

import bolts.Continuation;
import bolts.Task;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class MetawearChannel implements MethodChannel.MethodCallHandler {
    private final PluginRegistry.Registrar registrar;
    private final MetaWearBoard board;
    private final MethodChannel moduleChannel;
    private final MethodChannel deviceChannel;
    private final MethodChannel routeBuildChannel;

    public String getRootNamespace(){
        return FlutterMetawearPlugin.NAMESPACE + "/metawear/" + board.getMacAddress();
    }

    public MetaWearBoard getBoard(){
        return board;
    }


    public MetawearChannel(final PluginRegistry.Registrar registrar, final MetaWearBoard board){
        this.registrar = registrar;
        this.board = board;

        board.onUnexpectedDisconnect(new MetaWearBoard.UnexpectedDisconnectHandler() {
            @Override
            public void disconnected(int status) {
                clearHandlers();

            }
        });
        deviceChannel = new MethodChannel(registrar.messenger(),getRootNamespace());
        deviceChannel.setMethodCallHandler(this);

        moduleChannel = new MethodChannel(registrar.messenger(),getRootNamespace() + "/modules");
        moduleChannel.setMethodCallHandler(new MetawearModuleChannel(registrar, this));

        routeBuildChannel = new MethodChannel(registrar.messenger(),getRootNamespace() + "/routes/build");
        routeBuildChannel.setMethodCallHandler(new MetawearRouteBuildChannel(registrar,this,null));


    }

    private void clearHandlers(){
        registrar.messenger().setMessageHandler(getRootNamespace(),null);
        registrar.messenger().setMessageHandler(getRootNamespace() + "/modules",null);
        registrar.messenger().setMessageHandler(getRootNamespace() + "/routes/build",null);
    }


    @Override
    public void onMethodCall(final MethodCall methodCall, final MethodChannel.Result result) {
        final MetawearChannel metawearChannel = this;

        switch (methodCall.method){
            case "disconnect":
                board.disconnectAsync().continueWith(new Continuation<Void, Object>() {
                    @Override
                    public Object then(Task<Void> task) throws Exception {
                        result.success(true);
                        clearHandlers();
                        return null;
                    }
                });
                break;
            case "model":
                result.success(board.getModel().toString());
                break;
            case "device_info":
                board.readDeviceInformationAsync().continueWith(new Continuation<DeviceInformation, Object>() {
                    @Override
                    public Object then(Task<DeviceInformation> task) throws Exception {
                        final DeviceInformation deviceInformation = task.getResult();
                        result.success(new HashMap<String, Object>() {{
                            put("manufacturer", deviceInformation.manufacturer);
                            put("model_number", deviceInformation.modelNumber);
                            put("serial_number", deviceInformation.serialNumber);
                            put("firmware_revision", deviceInformation.firmwareRevision);
                            put("hardware_revision", deviceInformation.hardwareRevision);
                        }});
                        return null;
                    }
                });
                break;
            case "packed_acc_handler":
                metawearChannel.getBoard().getModule(Accelerometer.class).packedAcceleration()
                        .addRouteAsync(new MetawearRouteBuildChannel.ChannelRouteBuilder(registrar,this));
                break;
            case "acc_handler":
                Accelerometer accelerometer;
                if( (accelerometer = metawearChannel.getBoard().getModule(Accelerometer.class)) != null) {
                    MetawearRouteBuildChannel.ChannelRouteBuilder channel = new MetawearRouteBuildChannel.ChannelRouteBuilder(registrar, this);
                    accelerometer.acceleration().addRouteAsync(channel);
                    result.success(channel.getNamespace());
                }
                break;
        }
    }

    public interface MetawearDispose{
        void onDispose();
    }

}
