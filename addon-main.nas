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

    # load dialogs
    var dialogs   = ["littlenavmap-settings"];
    forindex (var i; dialogs) {
      gui.Dialog.new("/sim/gui/dialogs/" ~ dialogs[i] ~ "/dialog", my_root_path ~ "/gui/" ~ dialogs[i] ~ ".xml");
    }

    var data = {
	  label   : "LittleNavMap",
      name    : "littlenavmap",
      binding : { command : "dialog-show", "dialog-name" : "littlenavmap-settings" },
      enabled : "true",
	};

    # register in the main menu
    foreach(var item; props.getNode("/sim/menubar/default/menu[1]").getChildren("item")) {
      if (item.getValue("name") == "littlenavmap") {
  		    return;
      }
    }
	props.globals.getNode("/sim/menubar/default/menu[1]").addChild("item").setValues(data);

	fgcommand("gui-redraw");

    var init = setlistener("/sim/signals/fdm-initialized", func() {
      removelistener(init); # only call once

      fgcommand("add-io-channel",
        props.Node.new({
            "config" : "generic,socket,out,1,localhost,7755,udp,[addon=com.slawekmikula.flightgear.LittleNavMap]/Protocol/littlenavmap",
            "name" : "littlenavmap"
        })
      );
    });

    var exit = setlistener("/sim/signals/exit", func() {
      removelistener(exit); # only call once

      fgcommand("remove-io-channel",
        props.Node.new({ 
            "name" : "littlenavmap"
        })
      );
    });
}
