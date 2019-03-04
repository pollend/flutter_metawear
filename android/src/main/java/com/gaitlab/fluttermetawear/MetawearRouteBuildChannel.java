package com.gaitlab.fluttermetawear;

import com.mbientlab.metawear.Data;
import com.mbientlab.metawear.Subscriber;
import com.mbientlab.metawear.builder.RouteBuilder;
import com.mbientlab.metawear.builder.RouteComponent;
import com.mbientlab.metawear.module.Accelerometer;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class MetawearRouteBuildChannel implements MethodChannel.MethodCallHandler {
    private final PluginRegistry.Registrar registrar;
    private final MetawearChannel metawearChannel;
    private final RouteComponent routeComponent;
    private transient boolean isReleased = false;
    private final List<RouteCallback> callbacks = new ArrayList<>();


    public MetawearRouteBuildChannel(PluginRegistry.Registrar registrar, MetawearChannel channel, RouteComponent routeComponent) {
        this.registrar = registrar;
        this.metawearChannel = channel;
        this.routeComponent = routeComponent;
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        switch (methodCall.method){
            case "steam":
                routeComponent.stream(new Subscriber() {
                    @Override
                    public void apply(Data data, Object... env) {

                    }
                });
                break;
            case "end":
                isReleased = true;
                break;
        }
        this.notifyAll();
    }

    public static class ChannelRouteBuilder implements RouteBuilder {
        private final PluginRegistry.Registrar registrar;
        private final MetawearChannel metawearChannel;
        private MetawearRouteBuildChannel routeChannel;
        private String namespace;

        public ChannelRouteBuilder(PluginRegistry.Registrar registrar, MetawearChannel channel) {
            this.registrar = registrar;
            this.metawearChannel = channel;
            this.namespace = metawearChannel.getRootNamespace() + "/" + UUID.randomUUID().toString();
        }
        public String getNamespace(){
            return namespace;
        }

        @Override
        public void configure(RouteComponent source) {
            this.routeChannel = new MetawearRouteBuildChannel(registrar,metawearChannel,source);
            synchronized (this.routeChannel){
                try{
                    while (!this.routeChannel.isReleased) {
                        this.routeChannel.wait();
                        for(RouteCallback callback : this.routeChannel.callbacks){
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

    interface RouteCallback{
        void run();
    }
}
