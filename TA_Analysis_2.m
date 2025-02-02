%TA Analysis 2.0 MATLAB script
%This generates the most common MATLAB plots required from a Transient
%Absorption MFE experiment.
%Author: Andrew Markham - Part II, Timmel Group 2019-2020
%Reads in data files generated by LABVIEW Data Load v11 software available
%at https://git.chem.ox.ac.uk/crtgroup/ta-data-load-labview.git
%Use at your own risk!

%Hints:
%If you are trying to see how this program works, if you are not already
%familiar with Classes or anonymous functions in MATLAB, I would recommend 
%looking these up, otherwise you'll find this hard to follow.

clear      %Clear all variables
close all  %Close all active figures
clc        %Clear the console

%Check whether this file has the necessary class definitions it needs to run 
check_class_exists('FigParObject')
check_class_exists('Experiment')
check_class_exists('LineObject')
check_class_exists('XUnits')

%System parameters to tune functionality. Feel free to change at will:
%--------------------------------------------------------------------------
%Default directory to search for parameter files:
search_dir = 'C:\Users/';

%Plot all times on spectral evolution (true), or just those before end of time
%window? (false)
plot_all_evolution = false;
%--------------------------------------------------------------------------

%Ask the user for the parameter files for eacdh experiment
%par_paths is cell array, num_files integer
[par_paths, num_files] = get_par_files(search_dir);

tic        %Start the runtime timer

%Import experimental data from files
expts = arrayfun(@(i) Experiment(par_paths{i}), 1:num_files, 'UniformOutput', false);

%Determine what graphs should be plotted
if num_files == 1
    %Only one experiment, so plot the basics:
    all_dda_figs = plotDDA(expts{1});
    %close all
    all_mfe_figs = plotMFE(expts{1});
    all_kin_figs = plotAllKinetics(expts{1});
    %close all
    evolution_fig = plotSpectralEvolution(expts{1},plot_all_evolution);
    
    disp(sprintf('Figures saved to %sFigures \n',expts{1}.directory))
    close all
else
    %NB: this code currently assumes that all experiments have equivalent
    %kinetic species in equivalent positions in that metadata file
    %Also assumes same time scale for the experiment
    %Normalisation doesn't work either
    
    %Enter in following array which plots required
    %1 is on, 2 is off, 3 is sub, 4 is mfe
    onOffSubMfe = [1:4];
    normalise = false;
    cross_figs = plotAcross(expts,onOffSubMfe, normalise);
    
    close all
end

toc    %End timer on last line of execution

function whichPlots = whichCrossPlots(expts)
    %Determines which cross-experiment plots are useful to be plotted
    
    %Creates arrays of the parameters for each experiment
    temperatures = arrayfun(@(i) expts{i}.temperature, 1:size(expts, 2));
    fields = arrayfun(@(i) expts{i}.field, 1:size(expts, 2));
    wavelengths = arrayfun(@(i) expts{i}.excitation_wavelength, 1:size(expts, 2));

    %Determine whether each property is unique or not 
    whichPlots.temperature = (howManyDifferent(temperatures) > 1);
    whichPlots.field = (howManyDifferent(fields) > 1);
    whichPlots.wavelength = (howManyDifferent(wavelengths) > 1);
end

function integer = howManyDifferent(array)
    %Determines how many different values of a given array are unique
    integer = max(size(unique(array,'stable')));
end

function figs = plotAcross(expts, onOffSubMfe, normalise)
    %Which of the kinetic plots are desired?
    
    num_species = min(arrayfun(@(i) expts{i}.num_species, 1:size(expts, 2)));
    
    if normalise
        max_logical_value = 1;
    else
        max_logical_value = 0;
    end
    
    figs = arrayfun(@(i) arrayfun(@(j) arrayfun(@(k) plotMultipleExperiments(expts,0,onOffSubMfe(j),k),1:num_species,'UniformOutput',false), 1:size(onOffSubMfe,2), 'UniformOutput',false), 0:max_logical_value,'UniformOutput',false);
end

function figs = plotMultipleExperiments(expts, normalise, plot_index, spec_no)
    %Generates a cell array containing the requested plots for each species
    %TODO: update comments in this section
    
    %Parameters passed:
    %expts is cell array of Experiment objects
    %normalise is an integer of 0 or 1 (but can be treated as a logical)
    %plot_index corresponds to 1 (on), 2 (off), 3 (sub), 4(mfe)
    
    %Automatically saves to the desktop
    directory = 'C:\Users\crtgroup\Desktop\';
    
    whichPlots = whichCrossPlots(expts);
    lambda = '\lambda_{ex}';
    
    num_expts = size(expts,2);
    
    if ~whichPlots.field
        title_field = sprintf('%.1f mT ',expts{1}.field);
        leg_field = @(expt_no) '';
    else
        title_field = '';
        leg_field = @(expt_no) sprintf('%.1f mT ',expts{expt_no}.field);
    end
    if ~whichPlots.wavelength
        title_wavelength = sprintf('%s= %u nm ',lambda,expts{1}.excitation_wavelength);
        leg_wavelength = @(expt_no) '';
    else
        title_wavelength = '';
        leg_wavelength = @(expt_no) sprintf('%s= %u nm ',lambda,expts{expt_no}.excitation_wavelength);
    end
    if ~whichPlots.temperature
        title_temp = sprintf('%u K',expts{1}.temperature);
        leg_temp = @(expt_no) '';
        colours = lines(num_expts);
    else
        title_temp = '';
        leg_temp = @(expt_no) sprintf('%u K',expts{expt_no}.temperature);
        if num_expts == 3
            colours = [0 0 1; 0 1 1; 1 0 0];
        elseif num_expts == 2
            colours = [0 0 1; 1 0 0];
        else
            %colours = [jet(num_expts-1); [1 0 0]];
            colours = jet(num_expts);
        end
    end
    
    %Line parameters

    title_core = {'On kinetics', 'Off kinetics', 'Sub kinetics', '%MFE kinetics'};
    
    if normalise == 1
        filename_head = {'on_kinetics_normalised', 'off_kinetics_normalised', 'sub_kinetics_normalised','mfe_kinetics_normalised'};
    else
        filename_head = {'on_kinetics', 'off_kinetics', 'sub_kinetics','mfe_kinetics'};
    end
    if plot_index == 4
        y_limits = [-100 100];
        %{
        lims = arrayfun(@(i) , 1:num_expts,'UniformOutput',false);
        lim = @(expt_no) get_y_limits(expts{i}, spec_no);
        upper_lim = 
        y_limits = [min(lims(1)) max(lims(2))];
        %}
    else
        y_limits = [NaN NaN];
    end
    
    location = {'northeast','northeast','northeast','northeast'};
    x_label = {'\DeltaA' '\DeltaA' '\Delta\DeltaA' '%MFE'};
    zero_line  = [false false true true];
    
    %Create function to return the legend entry for a given chemical species
    if whichPlots.temperature || whichPlots.field || whichPlots.wavelength
        legend = @(expt_no) sprintf('%s at %s%s%s',strtrim(expts{expt_no}.kinetics_legend{spec_no,1}), leg_wavelength(expt_no), leg_field(expt_no), leg_temp(expt_no));   
    else
        legend = @(expt_no) sprintf('%s',strtrim(expts{expt_no}.kinetics_legend{spec_no,1}));
    end
    
    if whichPlots.temperature && whichPlots.field && whichPlots.wavelength
        title = sprintf('%s %s\n(%s%s%s)',expts{1}.sample_name,title_core{plot_index},title_wavelength,title_field,title_temp);
    else
        title = sprintf('%s %s',expts{1}.sample_name,title_core{plot_index});
    end
        
    %Generate a 2D nested cell array containing LineObject data for each figure
    %fig_lines is 1xn cell array, each element containing a 1xm array of LineObjects
    %Where n is the number of separate DDA figures, and m is the number of lines in each
    fig_lines = arrayfun(@(expt_no) LineObject(expts{expt_no}.kinetics.time,expts{expt_no}.read_data('kinetics',plot_index,spec_no),legend(expt_no),colours(expt_no,:),'-',0.5,'none'), 1:num_expts,'UniformOutput',false);
 
    %Generate a cell array of FigParObject instances to contain plotting parameters for each figure 
    fig_par = FigParObject(title,x_label(plot_index),zero_line(plot_index),14,expts{1}.t_units,expts{1}.time_window,y_limits,location{plot_index},1,'tex');
    
    %Generate the filename for a given figure
    filename = sprintf('%s_species_%u',filename_head{plot_index},spec_no);
    
    %Generate figure, one for each chemical species
    figs = gen_figure(fig_par,fig_lines,directory,filename);
end

function figs = plotAllKinetics(expt)
    %Plots a single experiment's kinetic data for each species on a separate figure
    
    %Line parameters
    lines_per_species = 3;
    colors = [1 0 0; 0 0 0; 0 0 1];     %red, black, blue convention in Timmel group for on/off/sub
    title_core = @(species) sprintf('%s kinetics',strtrim(expt.kinetics_legend{species,1}));
    filename_head = 'all';
    y_limits = @(species) [NaN NaN];
    location = 'best';
    x_label = '\DeltaA';
    legend_text = {'On';'Off';'Sub'};
    
    %Create function to return the legend entry for a given chemical species 
    legend = @(species) legend_text{species};
    
    color = @(line_no) colors(line_no,:);
    
    %Generate a 2D nested cell array containing LineObject data for each figure
    %fig_lines is 1xn cell array, each element containing a 1xm array of LineObjects
    %Where n is the number of separate DDA figures, and m is the number of lines in each
    fig_lines = arrayfun(@(spec_no) arrayfun(@(line_no) LineObject(expt.kinetics.time,expt.read_data('kinetics',line_no,spec_no),legend(line_no),color(line_no),'-',0.5,'none'), 1:lines_per_species,'UniformOutput',false), 1:expt.num_species,'UniformOutput',false);
 
    figs = plotKinetic(expt, fig_lines, x_label, location, y_limits, filename_head, title_core);
end

function figs = plotDDA(expt)
    %Plots a single experiment's MFE kinetic data for each species on a separate figure
    
    %Line parameters
    lines_per_species = 1;
    color = [0 0.4470 0.7410];  %Feel free to change
    title_core = @(species) 'MFE kinetics';
    filename_head = 'dda';
    y_limits = @(species) [NaN NaN];
    location = 'northeast';
    x_label = '\Delta\DeltaA';
    
    %Create function to return the legend entry for a given chemical species 
    legend = @(species) strtrim(expt.kinetics_legend{species,1});
    
    %Generate a 2D nested cell array containing LineObject data for each figure
    %fig_lines is 1xn cell array, each element containing a 1xm array of LineObjects
    %Where n is the number of separate DDA figures, and m is the number of lines in each
    fig_lines = arrayfun(@(spec_no) arrayfun(@(line_no) LineObject(expt.kinetics.time,expt.read_data('kinetics',3,spec_no),legend(spec_no),color,'-',0.5,'none'), 1:lines_per_species,'UniformOutput',false), 1:expt.num_species,'UniformOutput',false);
 
    figs = plotKinetic(expt, fig_lines, x_label, location, y_limits, filename_head, title_core);
end

function figs = plotMFE(expt)
    %Plots a single experiment's MFE kinetic data for each species on a separate figure
   
    %Line parameters
    lines_per_species = 1;
    color = [0 0.4470 0.7410];  %Feel free to change
    title_core = @(species) '%MFE kinetics';
    filename_head = 'mfe';
    y_limits = @(species) get_y_limits(expt,species);
    location = 'northeast';
    x_label = '%MFE';
    
    %Create function to return the legend entry for a given chemical species 
    legend = @(species) strtrim(expt.kinetics_legend{species,1});
    
    %Generate a 2D nested cell array containing LineObject data for each figure
    %fig_lines is 1xn cell array, each element containing a 1xm array of LineObjects
    %Where n is the number of separate %MFE figures, and m is the number of lines in each
    fig_lines = arrayfun(@(spec_no) arrayfun(@(line_no) LineObject(expt.kinetics.time,expt.read_data('kinetics',4,spec_no),legend(spec_no),color,'-',0.5,'none'), 1:lines_per_species,'UniformOutput',false), 1:expt.num_species,'UniformOutput',false);
    
    figs = plotKinetic(expt, fig_lines, x_label, location, y_limits, filename_head, title_core);
end

function figs = plotKinetic(expt, fig_lines, x_label, location, y_limits, filename_head, title_core)
    %Generates an arbitrary kinetic plot from the data passed
    
    %Parameters passed:
    %expt is Experiment object
    %fig_lines is cell array of cell arrays of LineObjects
    %Strings: x_label, location, filename_head
    %Functions: y_limits(species), title_core(species)

    %Create function to generate the title for a given species
    title = @(species) sprintf('%s %s',expt.sample_name,title_core(species),title_line_2(expt));
    
    %Generate a cell array of FigParObject instances to contain plotting parameters for each figure 
    fig_par = arrayfun(@(species) FigParObject(title(species),x_label,true,14,expt.t_units,expt.time_window,y_limits(species),location,1,'tex'), 1:expt.num_species,'UniformOutput',false);
    
    %Generate the filename for a given figure
    filename = @(species) sprintf('%s_kinetics_species_%u',filename_head,species);
    
    %Create a 1xn cell array of figures, one for each chemical species
    figs = arrayfun(@(species) gen_figure(fig_par{species},fig_lines{species},expt.directory,filename(species)), 1:expt.num_species,'UniformOutput',false);
end

function figs = plotSpectralEvolution(expt,plot_all)
    %Plots a single experiment's MFE kinetic data for each species on a separate figure
   
    %Parameters
    y_label = {'\DeltaA';'\DeltaA';'\Delta\DeltaA';'%MFE'};
    
    %Customise these settings to fine-tune legend properties
    lines_per_species = 30;
    legend_entries_per_column = 10;
    
    %Which spectral data to plot? Recommended is off (i.e. 2)
    which_field = 2; %1 = on, 2 = off, 3 = sub, 4 = mfe
    
    if plot_all || (expt.spectrum.time(2,end) <= expt.time_window(2))
        %Don't limit spectral evolution plot to data in parameter file's time window
        last_time = size(expt.spectrum.on,2);
    else
        %Limit spectral evolution plot to data in parameter file's time window
        last_time = find(expt.spectrum.time(2,:) > expt.time_window(2),1,'first');    
    end
    
    plots_to_display = round(linspace(1,last_time,lines_per_species));
    num_columns = ceil(lines_per_species ./ legend_entries_per_column);

    color = jet(lines_per_species);
    
    %Generate a 2D nested cell array containing LineObject data for each figure
    %fig_lines is 1xn cell array, each element containing a 1xm array of LineObjects
    %Where n is the number of separate %MFE figures, and m is the number of lines in each
    fig_lines = arrayfun(@(line_no) LineObject(expt.spectrum.wavelength,expt.read_data('spectrum',which_field,plots_to_display(line_no)),evolution_legend(expt,plots_to_display(line_no)),color(line_no, :),'-',0.5,'none'), 1:lines_per_species,'UniformOutput',false);
 
    %Store plot title
    title = sprintf('%s spectral evolution%s',expt.sample_name,title_line_2(expt));
    
    %Generate a cell array of FigParObject instances to contain plotting parameters for each figure
    fig_par = FigParObject(title,y_label{which_field},true,14,XUnits.Nanometres,expt.wavelength_window,[NaN NaN],'northeast',num_columns,'latex');
 
    %Generate the filename for a given figur
    filename = sprintf('spectral_evolution_%u_timestamp%s',lines_per_species, plural(lines_per_species));
    
    %Create a 1xn cell array of figures, one for each chemical species
    figs = gen_figure(fig_par,fig_lines,expt.directory,filename);
end

function text = plural(num)
    %Pretty self-explanatory
    if num == 1
        text = '';
    else
        text = 's';
    end
end

function text = title_line_2(expt)
    %Returns the second line of title text for a figure
    lambda = '\lambda_{ex}';
    text = sprintf('\n(%s= %u nm, %.1f mT, %u K)',lambda,expt.excitation_wavelength,expt.field,expt.temperature);
end

function label = evolution_legend(expt,spec_no)
    %Returns the legend entry to be plotted for a given chemical species
    
    dt = expt.spectrum.time(4,spec_no);
    t1 = expt.spectrum.time(2,spec_no);

    half_space = '\,';
    if dt == 0
        %Single wavelength
        label = sprintf('%.1f%s%s',t1,half_space,expt.t_units.latex);
    else
        %Averaged over several wavelengths
        t2 = expt.spectrum.time(3,spec_no);
        label = sprintf('%.1f--%.1f%s%s',t1,t2,half_space,expt.t_units.latex);
    end
end

function limits = get_y_limits(expt,spec_no)
    %Determine the y limits to use for an mfe plot
    %mfe data before t=0 are noisy and so are filtered out
    
    mfe_data = expt.read_data('kinetics',4,spec_no);
    post_zero_mfe_data = mfe_data(expt.kinetics.time > 0);
    limits = [floor(min(post_zero_mfe_data))  ceil(max(post_zero_mfe_data))];
    
    %Remove nonsensically large limits
    if limits(1) < -100
        limits(1) = -100;
    end
    if limits(2) > 100
        limits(2) = 100;
    end
end

function fig = gen_figure(par,fig_lines,directory,filename)
    %par is FigParObject
    %fig_lines is 1xn cell array of LineObjects
    %directory and filename are strings specifying save parameters

    %Generate the figure specified in the passed  
    fig = figure; ax = axes; hold on; box on;
    ax.FontSize = par.font_size;
    title(par.title)
    xlabel(par.x_label)
    ylabel(par.y_label)
    num_lines = max(size(fig_lines));
    
    %Plot each line on this figure
    arrayfun(@(line) fig_lines{line}.plot, 1:num_lines,'UniformOutput',false);
    
    xlim(par.x_limits)
    
    %NaN values of y_limits indicate the automatic y limits are not to be overriden
    if isnan(par.y_limits) == [0 0]
       ylim(par.y_limits)
    end 
    
    if par.zero_line    
        plot(par.x_limits,[0 0],'k--')
    end
    
    legend(arrayfun(@(line) fig_lines{line}.legend, 1:num_lines,'UniformOutput',false),'Location',par.leg.loc,'NumColumns',par.leg.num_columns,'Interpreter',par.leg.interpreter)
    hold off
    
    %Save figure generated
    save_all(fig,directory,filename,'true')
end 

function save_all(fig,dir,filename,overwrite)
    %Save the passed figure as .fig, .png, .svg
    path = strcat(dir,'Figures');
    if ~exist(path,'dir')
        mkdir(path)
    end
    
    path = strcat(dir,'Figures\');
    full_filename  = strcat(path,filename);
    
    if ~overwrite
        %Don't overwrite, find the next free filename
        i = 0;
        if exist(strcat(full_filename,'.fig'), 'file') == 2
            increment = true;
            while increment
                i = i + 1;
                full_filename = sprintf('%s%s - Version %u',path,filename,i);
                increment = exist(sprintf('%s%s - Version %u.fig',path,filename,i), 'file') ~= 0;
            end
        end
    end
    
    savefig(fig,full_filename,'compact')
    saveas(fig,strcat(full_filename,'.png'))
    saveas(fig,strcat(full_filename,'.svg'))
end

function [full_paths, files_selected] = get_par_files(dir)
    %Collects and returns the paths of the parameter files from the user
    
    %Limit search results only to parameter files
    search_path = strcat(dir,'*plotting parameters.txt');

    %Check whether the directory path specified is valid
    if ~exist(dir, 'dir')
       %End program if neither of the specified directories exist
       error('Default directory cannot be found. Please change initial value of seearch_dir variable.')
    end
    
    %Variables to track progress of iteration
    get_another_file = true;
    i = 1;

    %Stores paths and file names of parameter files
    full_paths = {};
    
    while get_another_file   
        dialog_text = sprintf('Select the %s parameters file', get_ordinality(i));

        [filename, path] = uigetfile(search_path,dialog_text);

        %End program if 'Cancel' pressed by user
        if filename == 0
            get_another_file = false;
            if i == 1
                error('Runtime was terminated by user: no file selected')
            end
        else
            full_paths{i,1} = strcat(path,filename);
            i = i + 1;
        end 
    end

    files_selected = i - 1;
    fprintf('%u files selected\n',files_selected)
end

function ordinal = get_ordinality(number)
    %Outputs the ordinality of the number passed
    switch mod(number, 10)
        case 1
            ordinal = sprintf('%ust', number);
        case 2
            ordinal = sprintf('%und', number);
        case 3
            ordinal = sprintf('%urd', number);
        otherwise
            ordinal = sprintf('%uth', number);    
    end
end

function check_class_exists(name)
    %Check whether a given class exists - name is a string
    if ~exist(name,'class')
        error(strcat(name,'.m class definition file not found. Please ensure it is in the same directory as this file.'))
    end
end

