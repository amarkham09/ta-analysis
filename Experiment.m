%This script defines the class "Experiment" for use with the script
%TA_Analysis_2_beta.m
%Instances of this class are used to store the data initially read in
%with one object created for each TA experimental run.

classdef Experiment
    properties
        %Properties read in from "plotting parameters.txt" experiment file:
        directory             %String:  The directory containing experimental data
        kinetics_prefix       %String:  The filename chosen for the kinetics files exported by "Data Load v11.vi"
        spectrum_prefix       %String:  The filename chosen for the spectrum files exported by "Data Load v11.vi"
        kinetics_labels_file  %String:  The csv file in which the labels for each kinetics species is stored
        invert                %Logical: Are the y data upside down (i.e. is it a near-IR TA experiment)?
        sample_name           %String:  What is the composition of the sample? e.g. Triad K, Kd, ErCRY
        temperature           %Double:  Temperature of the cryostat for this experiment (in Kelvin)
        field                 %Double:  Field applied in "on" steps (in mT)
        excitation_wavelength %Double:  At what wavelength was the pump laser set? (in nm)
        time_window           %1x2 double: The left and right limits of kinetics plots (originally in microseconds)
        wavelength_window     %1x2 double: The left and right limits of spectral plots (in nanometres)
        solvent               %String:  The solvent in which the experiment was carried out
        
        %Properties read from file specified in kinetics_labels_file:
        kinetics_legend       %nx1 cell array: Contains labels for each kinetics species 
        num_species           %Integer:        The number of rows in kinetics_legend
        
        %Struct of 2D arrays of doubles containing kinetics data from file specified by kinetics_prefix:
        %.on, .off, .sub fields contain y data for on, off and sub files (originally in seconds)
        %.percent contains the calculated percentage MFE as a function of wavelength
        %.time field contains x (time) data from these files (originally in seconds)
        %.wavelength contains wavelength region over which each species' kinetic data was averaged (in nanometres)
        kinetics
        
        %Struct of 2D arrays of doubles containing spectral data from file specified by spectrum_prefix:
        %.on, .off, .sub fields contain y data for on, off and sub files (originally in seconds)
        %.percent contains the calculated percentage MFE for each species
        %.wavelength field contains x (wavelength) data from these files (in nanometres)
        %.time contains times region over which each spectral snapshot was averaged (originally in seconds)
        spectrum
        
        %Other calculated properties:
        t_units      %What are the units of the time variables listed above?
        save_dir     %Where are the figures generated to be saved?
    end
    methods
        function obj = Experiment(path)
            %This is the constructor function for an instance of the class 
            %Experiment, i.e. it creates an Experiment object with the
            %properties listed above which are imported from experimental data files
            exp_pars = readtable(path);
            obj.directory = char(exp_pars{1,2});
            obj.kinetics_prefix = char(exp_pars{2,2});
            obj.spectrum_prefix = char(exp_pars{3,2});
            obj.kinetics_labels_file = char(exp_pars{4,2});
            obj.invert = strcmpi(exp_pars{5,2},'true');
            obj.sample_name = char(exp_pars{6,2});
            obj.temperature = str2double(exp_pars{7,2});
            obj.field = str2double(exp_pars{8,2});
            obj.excitation_wavelength = str2double(exp_pars{9,2});
            obj.time_window = str2double(exp_pars{10:11,2})';
            obj.wavelength_window = str2double(exp_pars{12:13,2})';
            obj.solvent = char(exp_pars{14,2});
            obj.kinetics_legend = obj.write_data('labels');
            obj.num_species = max(size(obj.kinetics_legend));
            obj.kinetics.on = obj.write_data('kinetics','y','on');
            obj.kinetics.off = obj.write_data('kinetics','y','off');
            obj.kinetics.sub = obj.write_data('kinetics','y','sub');
            obj.kinetics.percent = 100 .* obj.kinetics.sub ./ obj.kinetics.off;
            obj.kinetics.time = obj.write_data('kinetics','x','on');
            obj.kinetics.wavelength = obj.write_data('kinetics','header','on');
            obj.spectrum.on = obj.write_data('spectrum','y','on');
            obj.spectrum.off = obj.write_data('spectrum','y','off');
            obj.spectrum.sub = obj.write_data('spectrum','y','sub');
            obj.spectrum.percent = 100 .* obj.spectrum.sub ./ obj.spectrum.off;
            obj.spectrum.wavelength = obj.write_data('spectrum','x','on');
            obj.spectrum.time = obj.write_data('spectrum','header','on');
            
            %This constant determines the time (in microseconds) the
            %program automatically draws the line between kinetics plots in
            %nanoseconds or in microseconds
            time_cutoff = 1.5;
            
            if obj.time_window(2) < time_cutoff
                obj.t_units = XUnits.Nanoseconds;
                %Convert from microseconds to nanoseconds
                obj.time_window = obj.time_window .* 1e3;
                %Convert from seconds to nanoseconds
                obj.kinetics.time = obj.kinetics.time .* 1e9;
                obj.spectrum.time = obj.spectrum.time .* 1e9;
            else
                obj.t_units = XUnits.Microseconds;
                %Convert from seconds to microseconds
                obj.kinetics.time = obj.kinetics.time .* 1e6;
                obj.spectrum.time = obj.spectrum.time .* 1e6;
            end
        end
        function data = read_data(obj,category,line_no, spec_no)
            %As structs cannot be indexed with integers, this function
            %allows **reading** of kinetic or spectral data by an index 
            %(to neaten the constructor function above)
            
            %Parameter:
            %obj - required by MATLAB as the first parameter, the
                %Experiment object itself. NB: when calling this function,
                %you don't need to pass this, i.e. call the following:
                %write_data(category,x_or_y,onOffSub)
            %category - is the data required kinetic, spectral or heading data from the relevant file?
            %line_no - 1 = on, 2 = off, 3 = sub, 4 = mfe
            %spec_no - the number of the species 
           
            switch category
                case 'kinetics'
                    switch line_no
                        case 1
                            data = obj.kinetics.on(:,spec_no);
                        case 2
                            data = obj.kinetics.off(:,spec_no);
                        case 3
                            data = obj.kinetics.sub(:,spec_no);
                        case 4
                            data = obj.kinetics.percent(:,spec_no);
                        otherwise
                            error('Experiment.read_data passed invalid value of parameter line_no.\nValid values are 1 (on), 2 (off), 3 (sub) or 4 (%MFE)')   
                    end
                case 'spectrum'
                    switch line_no
                        case 1
                            data = obj.spectrum.on(:,spec_no);
                        case 2
                            data = obj.spectrum.off(:,spec_no);
                        case 3
                            data = obj.spectrum.sub(:,spec_no);
                        case 4
                            data = obj.kinetics.percent(:,spec_no);
                        otherwise
                            error('Experiment.read_data passed invalid value of parameter line_no.\nValid values are 1 (on), 2 (off), 3 (sub) or 4 (%MFE)')
                    end
                otherwise
                    error("Invalid category parameter passed to Experiment.read_data method.")
            end 
        end
        function data = write_data(obj,category,x_or_y,onOffSub)
            %As structs cannot be indexed with integers, this function
            %allows **assignment** of kinetic or spectral data by an index 
            %(to neaten the constructor function above)
            
            %Parameter:
            %obj - required by MATLAB as the first parameter, the
                %Experiment object itself. NB: when calling this function,
                %you don't need to pass this, i.e. call the following:
                %write_data(category,x_or_y,onOffSub)
            %category - is the data required kinetic, spectral or heading data from the relevant file?
            %x_or_y - return the file's x or y data?
            %onOffSub - return on, off, or sub data?
           
            switch category
                case 'kinetics'
                    data = obj.csv_read(obj.kinetics_prefix,x_or_y,onOffSub);
                case 'spectrum'
                    data = obj.csv_read(obj.spectrum_prefix,x_or_y,onOffSub);
                case 'labels'
                    %This is a txt file so cannot be read by a csv
                    path = strcat(obj.directory,obj.kinetics_labels_file);
                    data = table2cell(readtable(path,'ReadVariableNames',true,'Delimiter',','));
                otherwise
                    error("Invalid parameter passed to Experiment.data_path method.")
            end 
        end
        
        function data = csv_read(obj,prefix,x_or_y,onOffSub)
            %To neaten up above code 
            raw_data =  dlmread(strcat(obj.directory,prefix,'_',onOffSub,'.csv'));
            switch x_or_y
                case 'x'
                    data = raw_data(5:end,1);
                case 'y'
                    %Inverts the y data if necessary due to near-IR data collection bug in EOS software
                    if obj.invert
                        data = raw_data(5:end,2:end) .* -1;
                    else
                        data = raw_data(5:end,2:end);
                    end
                case 'header'
                    data = raw_data(1:4,2:end);
            end
        end
    end
end


