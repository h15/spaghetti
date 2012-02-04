
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
        
        /**
         *  Fix vertical nav position.
         */
        var left = $("nav.vertical").position().left;
        $("nav.vertical").css( 'left', left - 436 );
    });
