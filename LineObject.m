%This script defines the class "LineObject" for use with the script
%TA_Analysis_2_beta.m
%Instances of this class are used to store the data used to plot each line
%on a given plot, with one object per line. As such, the LineObject is
%completely general and does not care what kind of plot is being
%constructed.

classdef LineObject
    properties
        x       %The x data to plot
        y       %The y data to plot
        legend  %The legend entry for this particular line
        color   %Type "doc LineColor" into Command Window for more info
        style   %Type "doc LineStyle" into Command Window for more info
        width   %Type "doc LineWidth" into Command Window for more info
        marker  %Type "doc MarkerStyle" into Command Window for more info
    end
    methods
        function obj = LineObject(x,y,legend,color,style,width,marker)
            %This is the constructor function for an instance of the class 
            %LineObject, i.e. it creates a LineObject object with the
            %properties listed above
            obj.x = x;
            obj.y = y;
            obj.legend = legend;
            obj.color = color;
            obj.style = style;
            obj.width = width;
            obj.marker = marker;
        end
        function p = plot(obj)
            %This method, called by obj.plot(), where obj is the LineObject
            %to plot, plots the line corresponding to the LineObject on the
            %current figure
            p = plot(obj.x,obj.y,'Color',obj.color,'LineStyle',obj.style,'LineWidth',obj.width,'Marker',obj.marker); 
        end
    end
end