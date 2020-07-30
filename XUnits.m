classdef XUnits
   enumeration
      Nanoseconds, Microseconds, Nanometres
   end
   methods
       function text = tex(obj)
           switch obj
               case XUnits.Microseconds
                   text = '\mus';
               case XUnits.Nanoseconds
                   text = 'ns';
               case XUnits.Nanometres
                   text = 'nm';
           end
       end
       function text = latex(obj)
           switch obj
               case XUnits.Microseconds
                   text = '$\mu$s';
               case XUnits.Nanoseconds
                   text = 'ns';
               case XUnits.Nanometres
                   text = 'nm';
           end
       end
       function text = variable(obj)
           switch obj
               case XUnits.Microseconds
                   text = 'Time';
               case XUnits.Nanoseconds
                   text = 'Time';
               case XUnits.Nanometres
                   text = 'Wavelength';
           end
       end
   end
end