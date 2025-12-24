OX INSTALL QUIDE

1. Download all dependencies!
Dependencies:
	ox_inventory | https://github.com/overextended/ox_inventory
	ox_lib | https://github.com/overextended/ox_lib
	ox_target | https://github.com/overextended/ox_target
	oxmysql | https://github.com/overextended/oxmysql

2. Add Images to your inventory
	ox_inventory > web > build > images
	Paste images from folder images to ox_inventory > web > build > img

3. Add Items to your inventory
	ox_inventory > data> items.lua

['burner_phone'] = {
    label = 'Burner Phone',
    weight = 200,
    stack = false,
    close = true,
    description = 'A disposable mobile phone for dirty work.',
    durability = true,
},

['radioactive_waste'] = {
	label = 'Radioactive Waste',
	weight = 45,
},

['refined_chemical'] = {
	label = 'Refined Chemicals',
	weight = 80,
},

4. add ensure sm_ugsystem into your server.cfg (make sure to start it after ox_lib and your target system!)


5. Enjoy your script!
