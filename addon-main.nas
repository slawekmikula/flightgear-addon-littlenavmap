#
# LittleNavMap addon
#
# Author: Slawek Mikula
# Started on December 2019

var main = func( addon ) {
    var root = addon.basePath;
    var myAddonId  = addon.id;
    var mySettingsRootPath = "/addons/by-id/" ~ myAddonId;
    var protocolInitialized = 0;

    var enabledNode = props.globals.getNode(mySettingsRootPath ~ "/enabled", 1);
    enabledNode.setAttribute("userarchive", "y");
    if (enabledNode.getValue() == nil) {
      enabledNode.setValue("1");
    }

    var refreshRateNode = props.globals.getNode(mySettingsRootPath ~ "/refresh-rate", 1);
    refreshRateNode.setAttribute("userarchive", "y");
    if (refreshRateNode.getValue() == nil) {
      refreshRateNode.setValue("10");
    }

    var udpHostNode = props.globals.getNode(mySettingsRootPath ~ "/udp-host", 1);
    udpHostNode.setAttribute("userarchive", "y");
    if (udpHostNode.getValue() == nil) {
      udpHostNode.setValue("localhost");
    }

    var udpPortNode = props.globals.getNode(mySettingsRootPath ~ "/udp-port", 1);
    udpPortNode.setAttribute("userarchive", "y");
    if (udpPortNode.getValue() == nil) {
      udpPortNode.setValue("7755");
    }

    var initProtocol = func() {
      if (protocolInitialized == 0) {
        var enabled = getprop(mySettingsRootPath ~ "/enabled") or "1";
        var refresh = getprop(mySettingsRootPath ~ "/refresh-rate") or "10";
        var udphost = getprop(mySettingsRootPath ~ "/udp-host") or "localhost";
        var udpport = getprop(mySettingsRootPath ~ "/udp-port") or "7755";

        if (enabled == 1) {
          var protocolstring = "generic,socket,out," ~ refresh ~ "," ~ udphost ~ "," ~ udpport ~ ",udp,littlenavmap";
          fgcommand("add-io-channel",
            props.Node.new({
                "config" : protocolstring,
                "name" : "littlenavmap"
            })
          );
          protocolInitialized = 1;
        }
      }
    };

    var shutdownProtocol = func() {
        if (protocolInitialized == 1) {
            fgcommand("remove-io-channel",
              props.Node.new({
                  "name" : "littlenavmap"
              })
            );
            protocolInitialized = 0;
        }
    }

    var buildAiShortListGenerator = func() {

        # fetch AI aircraft list
        var aircraft_list = props.globals.getNode("/ai/models").getChildren("aircraft");
        var items = "";

        foreach(var ai_aircraft; aircraft_list){
            var item = "";
            item = item ~ ai_aircraft.getNode("callsign").getValue() ~ "^";
            item = item ~ ai_aircraft.getNode("arrival-airport-id").getValue() ~ "^";
            item = item ~ ai_aircraft.getNode("departure-airport-id").getValue() ~ "^";
            item = item ~ ai_aircraft.getNode("position").getNode("altitude-ft").getValue() ~ "^";
            item = item ~ ai_aircraft.getNode("position").getNode("latitude-deg").getValue() ~ "^";
            item = item ~ ai_aircraft.getNode("position").getNode("longitude-deg").getValue();

            items = items ~ item ~ "|";
        }

        # save AI aircraft items
        var resultNode = props.globals.getNode("/addons/by-id/com.slawekmikula.flightgear.LittleNavMap/ai-short-list", 1);
        resultNode.setValue(items);
    }

    # update each 10 seconds AI aircraft list
    var timer = maketimer(10, buildAiShortListGenerator);

    var init = _setlistener(mySettingsRootPath ~ "/enabled", func() {
        if (getprop(mySettingsRootPath ~ "/enabled") == 1) {
            initProtocol();
        } else {
            shutdownProtocol();
        }
    });

    var init = setlistener("/sim/signals/fdm-initialized", func() {
        removelistener(init); # only call once
        if (getprop(mySettingsRootPath ~ "/enabled") == 1) {
            timer.start();
            initProtocol();
        }
    });

    var reinit_listener = _setlistener("/sim/signals/reinit", func {
        removelistener(reinit_listener); # only call once
        if (getprop(mySettingsRootPath ~ "/enabled") == 1) {
            timer.start();
            initProtocol();
        }
    });

    var exit_listener = setlistener("/sim/signals/exit", func() {
        removelistener(exit_listener); # only call once
        if (getprop(mySettingsRootPath ~ "/enabled") == 1) {
            timer.stop();
            shutdownProtocol();
        }
    });
}
