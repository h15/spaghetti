package Spaghetti::Util;
use utf8;

    sub rusToLatUrl
        {
            my $s = shift;
            
            $s =~ s/А/a/ig;
            $s =~ s/Б/b/ig;
            $s =~ s/В/v/ig;
            $s =~ s/Г/g/ig;
            $s =~ s/Д/d/ig;
            $s =~ s/Е/e/ig;
            $s =~ s/Ё/jo/ig;
            $s =~ s/Ж/zh/ig;
            $s =~ s/З/z/ig;
            $s =~ s/И/i/ig;
            $s =~ s/К/k/ig;
            $s =~ s/Л/l/ig;
            $s =~ s/М/m/ig;
            $s =~ s/Н/n/ig;
            $s =~ s/О/o/ig;
            $s =~ s/П/p/ig;
            $s =~ s/Р/r/ig;
            $s =~ s/С/s/ig;
            $s =~ s/Т/t/ig;
            $s =~ s/У/u/ig;
            $s =~ s/Ф/f/ig;
            $s =~ s/Х/h/ig;
            $s =~ s/Ц/c/ig;
            $s =~ s/Ч/ch/ig;
            $s =~ s/Щ/sch/ig;
            $s =~ s/Ш/sh/ig;
            $s =~ s/Ы/y/ig;
            $s =~ s/Э/e/ig;
            $s =~ s/Ю/ju/ig;
            $s =~ s/Я/ja/ig;
            
            $s =~ s/\s+/-/g;
            $s =~ s/[^0-9a-zA-Z\-]//g;
            $s;
        }

    sub escape
        {
            my $s = shift;
               $s =~ s/</&lt;/g;
               $s =~ s/>/&gt;/g;
               $s =~ s/'/&#39;/g;
               $s =~ s/ - / &mdash; /g;
            
            my $tag =
                qr/(?:a|b|i|u|s|div|span|ul|ol|li|h[1-6]|p|sub|sup|header|footer|nav|article|table|tr|td|th|strong|strike|blockquote|cite|br|img|hr)/;
                
            my $attr = qr/(?:href|style|class|title|alt|src|for)/;
            
            # Parse pare tag
            $s =~ s/\&lt;($tag)((?:\s+$attr="[^\\\"]*")*)\&gt;/<\1\2>/igs;
            
            # Parse single tag
            $s =~ s/\&lt;\/($tag)\&gt;/<\/\1>/igs;
            
            $s;
        }

1;
