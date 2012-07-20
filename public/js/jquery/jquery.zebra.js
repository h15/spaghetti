/*
 * jQuery Zebra v1.0.0 - http://www.linkexchanger.su/
 *
 * Copyright (c) 2008 Gennady Samkov
 * Licensed under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */
jQuery.fn.zebra = function(options){
    
	// настройки по умолчанию
	var options = jQuery.extend({
		bgEven: '#ffffff', // бэкграунд для четных строк
        bgOdd: '#f3f3f3', // бэкграунд для нечетных строк
        fontEven: '#000000', // цвет шрифта четных строк
        fontOdd: '#000000', // цвет шрифта нечетных строк
        /*bgHover: '#FBFBFB',*/ // бэкграунд при hover
        fontHover: '#000000' // цвет шрифта при hover
	},options);
	
	return this.each(function() {

		jQuery(this).find('tr:even')
		            .css('background-color', options.bgEven)
		            .css('color', options.fontEven)
		            .hover(
		                function () {
		                	jQuery(this).css('background-color', options.bgHover)
		                	       .css('color', options.fontHover);
		                }, 
                        function () {
                        	jQuery(this).css('background-color', options.bgEven)
                        	       .css('color', options.fontEven);
                        }
		            );
		
        jQuery(this).find('tr:odd')
                    .css('background-color', options.bgOdd)
                    .css('color', options.fontOdd)
                    .hover(
                        function () {
                        	jQuery(this).css('background-color', options.bgHover)
                        	       .css('color', options.fontHover);
                        }, 
                        function () {
                        	jQuery(this).css('background-color', options.bgOdd)
                        	       .css('color', options.fontOdd);
                        }
                    );
        
	});

};