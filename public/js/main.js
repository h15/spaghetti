
    $(document).ready(function(){
        /**
         *  Show / hide some area.
         */
        $('.showButton').click(function(){
            var id = $(this).attr('id').split('-').pop();
            
            $(this).hide();
            $('#hideButton-' + id).show();
            $('#hiddenArea-' + id).slideDown();
            
            return false;
        });
        
        $('.hideButton').click(function(){
            var id = $(this).attr('id').split('-').pop();
            
            $(this).hide();
            $('#showButton-' + id).show();
            $('#hiddenArea-' + id).slideUp();
            
            return false;
        });
    });
    
    function translit( str )
    {
        var tr = 
        {
            "А":"A","Б":"B","В":"V","Г":"G",
            "Д":"D","Е":"E","Ж":"J","З":"Z","И":"I",
            "Й":"Y","К":"K","Л":"L","М":"M","Н":"N",
            "О":"O","П":"P","Р":"R","С":"S","Т":"T",
            "У":"U","Ф":"F","Х":"H","Ц":"TS","Ч":"CH",
            "Ш":"SH","Щ":"SCH","Ъ":"","Ы":"YI","Ь":"",
            "Э":"E","Ю":"YU","Я":"YA","а":"a","б":"b",
            "в":"v","г":"g","д":"d","е":"e","ж":"j",
            "з":"z","и":"i","й":"y","к":"k","л":"l",
            "м":"m","н":"n","о":"o","п":"p","р":"r",
            "с":"s","т":"t","у":"u","ф":"f","х":"h",
            "ц":"ts","ч":"ch","ш":"sh","щ":"sch","ъ":"y",
            "ы":"yi","ь":"","э":"e","ю":"yu","я":"ya",' ':'_', 'ё':'e', 'Ё':'E',
        };
        
        var ary = str.split('');
        var re  = /[a-z0-9]/i;
        
        for ( var i = 0; i < str.length; ++i)
        {
            if (! ary[i].match(re) )
            {
                ary[i] = (tr[ ary[i] ] != undefined ? tr[ ary[i] ] : '');
            }
        }
        
        str = ary.join('');
        
        return str;
    }

