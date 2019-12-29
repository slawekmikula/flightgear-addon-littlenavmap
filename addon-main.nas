#
# LittleNavMap addon
#
# Author: Slawek Mikula
# Started on December 2019

var main = func( addon ) {
    var root = addon.basePath;
    var my_addon_id  = "com.slawekmikula.flightgear.LittleNavMap";
    var my_version   = getprop("/addons/by-id/" ~ my_addon_id ~ "/version");
    var my_root_path = getprop("/addons/by-id/" ~ my_addon_id ~ "/path");
    var my_settings_root_path = "/addons/by-id/" ~ my_addon_id ~ "/addon-devel/";

    # persistent settings
    var udpHostNode = props.globals.getNode(my_settings_root_path ~ "/udp-host", 1);
    udpHostNode.setAttribute("userarchive", "y");
    if (udpHostNode.getValue() == nil) {
      udpHostNode.setValue("localhost");
    }    
    var udpPortNode = props.globals.getNode(my_settings_root_path ~ "/udp-port", 1);
    udpPortNode.setAttribute("userarchive", "y");
    if (udpPortNode.getValue() == nil) {
      udpPortNode.setValue("7755");
    }

    var initProtocol = func() {
      var refresh = "1"; # refresh rate
      var udphost = getprop(my_settings_root_path ~ "udp-host") or "localhost";
      var udpport = getprop(my_settings_root_path ~ "udp-port") or "7755";
      var protocolstring = "generic,socket,out," ~ refresh ~ "," ~ udphost ~ "," ~ udpport ~ ",udp,[addon=" ~ my_addon_id ~ "]/Protocol/littlenavmap";

      fgcommand("add-io-channel",
        props.Node.new({
            "config" : protocolstring,
            "name" : "littlenavmap"
        })
      );
    };

    var init = _setlistener("/sim/signals/fdm-initialized", func() {
        removelistener(init); # only call once
        print("fdm-initialized");
        initProtocol();
    });

    var reinit_listener = _setlistener("/sim/signals/reinit", func {
        removelistener(reinit_listener); # only call once
        print("reinit");
        initProtocol();
    });

    var exit = _setlistener("/sim/signals/exit", func() {
      removelistener(exit); # only call once
      print("exit");
      fgcommand("remove-io-channel",
        props.Node.new({ 
            "name" : "littlenavmap"
        })
      );
    });
}
