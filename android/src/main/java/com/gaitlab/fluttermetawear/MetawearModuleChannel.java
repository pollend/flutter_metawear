package com.gaitlab.fluttermetawear;

import com.mbientlab.metawear.CodeBlock;
import com.mbientlab.metawear.Data;
import com.mbientlab.metawear.MetaWearBoard;
import com.mbientlab.metawear.Observer;
import com.mbientlab.metawear.Subscriber;
import com.mbientlab.metawear.builder.RouteBuilder;
import com.mbientlab.metawear.builder.RouteComponent;
import com.mbientlab.metawear.module.Accelerometer;
import com.mbientlab.metawear.module.Led;
import com.mbientlab.metawear.module.Settings;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import bolts.Continuation;
import bolts.Task;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class MetawearModuleChannel implements MethodChannel.MethodCallHandler{
    private final PluginRegistry.Registrar registrar;
    private final MetawearChannel metawearChannel;
    private boolean isReleased;
    private final List<ModuleCallback> callbacks = new ArrayList<>();
    private final boolean isRoot;


    public MetawearModuleChannel(PluginRegistry.Registrar registrar, MetawearChannel channel,boolean isRoot) {
        this.registrar = registrar;
        this.metawearChannel = channel;
        this.isReleased = false;
        this.isRoot = isRoot;
    }



    public boolean isChannelReleased(){
        if(metawearChannel == null)
            return true;
        return isReleased;
    }

    @Override
    public void onMethodCall(MethodCall methodCall, final MethodChannel.Result result) {
        switch (methodCall.method){
            case "acc_start":
                Accelerometer accelerometer = metawearChannel.getBoard().getModule(Accelerometer.class);
                accelerometer.start();
                break;
            case "acc_stop":
                break;
            case "configure_led":
                final Led led;
                if((led = metawearChannel.getBoard().getModule(Led.class)) != null) {
                    led.editPattern(Led.Color.BLUE, Led.PatternPreset.BLINK).repeatCount((byte) 2).commit();
                }

                break;
            case "settings_disconnect_handler":
                CodeBlockCallback callback = new MetawearModuleChannel.CodeBlockCallback(registrar,metawearChannel);
                metawearChannel.getBoard().getModule(Settings.class).onDisconnectAsync(callback);
                result.success(callback.getNamespace());
//                metawearChannel.getBoard().getModule(Settings.class).onDisconnectAsync(callback).continueWith(new Continuation<Observer, Object>() {
//                    @Override
//                    public Object then(Task<Observer> task) throws Exception {
//                        if(task.isFaulted()){
//
//                        } else if(task.isCompleted()) {
//                            result.success(Boolean.TRUE);
//                        }
//                        return null;
//                    }
//                });

                break;
            case "end":
                isReleased = true;
                break;
        }
        if(isRoot){
            for(ModuleCallback callback : callbacks){
                callback.run();
            }
        }
        this.notifyAll();
    }

    public static class CodeBlockCallback implements CodeBlock {
        private final PluginRegistry.Registrar registrar;
        private final MetawearChannel metawearChannel;
        private MetawearModuleChannel routeChannel;
        private String namespace;

        public CodeBlockCallback(PluginRegistry.Registrar registrar, MetawearChannel channel) {
            this.registrar = registrar;
            this.metawearChannel = channel;
            this.namespace = metawearChannel.getRootNamespace() + "/" + UUID.randomUUID().toString();
        }
        public String getNamespace(){
            return namespace;
        }

        @Override
        public void program() {

            this.routeChannel = new MetawearModuleChannel(registrar,metawearChannel,false);
            synchronized (this.routeChannel){
                try{
                    while (!this.routeChannel.isReleased) {
                        this.routeChannel.wait();
                        for(ModuleCallback callback : this.routeChannel.callbacks){
                            callback.run();
                        }
                    }
                }
                catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            registrar.messenger().setMessageHandler(namespace,null);
        }
    }

    interface ModuleCallback{
        void run();
    }
}
