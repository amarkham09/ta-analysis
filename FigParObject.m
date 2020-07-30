%This script defines the class "FigParObject" for use with the script
%TA_Analysis_2_beta.m
%Instances of this class are used to store the data used to plot all
%necessary text on a given figure.

classdef FigParObject
    %Object which stores the parameters for a given figure
    properties
        title     %String: the plot title
        x_label   %String: the x axis label
        y_label   %String: the y axis label
        zero_line %Logical: plot a y=0 dotted black line on the figure?
        font_size %Integer: Font size of all text
        x_limits  %1x2 Double array: Limits of the x axis
        y_limits  %1x2 Double array: Limits of the y axis
        leg       %struct containing legend properties (but not text):
                  %     leg.loc is the legend property Location
                  %     leg.num_columns is the legend property NumColumns
                  %     leg.interpreter is the interpreter i.e. 'none', 'latex' or 'tex' to use in displaying the legend text
    end
    methods
        function obj = FigParObject(title,y_label,zero_line,font,x_units,x_limits,y_limits,legend_location,legend_num_columns,interpreter)
            %This is the constructor function for an instance of the class 
            %FigParObject, i.e. it creates a FigParObject object with the
            %properties listed above
            %NB: x_units is an instance of the XUnits class, defined in
            %the XUnits.m file in the same directory as this file

            obj.title = title;
            obj.y_label = y_label;
            obj.zero_line = zero_line;
            obj.font_size = font;
            obj.x_limits = x_limits;
            obj.y_limits = y_limits;
            obj.leg.loc = legend_location;
            obj.leg.num_columns = legend_num_columns;
            obj.leg.interpreter = interpreter;
            obj.x_label = sprintf('%s / %s',x_units.variable, x_units.tex);
        end
    end
end