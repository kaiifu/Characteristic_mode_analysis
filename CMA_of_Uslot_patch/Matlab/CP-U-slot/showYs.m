function showYs(action,varargin)

% This function draws a vertical line that intersects the lines
% on the current axes and places a text box with the y position
% by the intersection point. It also appends the x-point position 
% to the x label
%
% The y values are interpolated between given points
% If the line has NaN, Inf or -Inf values these are ignored and the
% interpolation is using the closest points available
%
% >> showYs 
% without arguments will set the function as the buttondown callback 
% for the current axes.
% >> showYs(h) 
% where h is a valid axes handle will set the function as the buttondown 
% callback for the axes with handle h.
% 
% For example if you want to see the y values for a given x for the 
% current axes jus write showYs in the command line and click within
% the axes boundaries. 
% Clicking again will delete the text boxes, and so on.
%
% By clicking on the vertical line it is possible to drag it together 
% with the textboxes. To stop dragging the line, click on top of it again.
%
% For an example type showYs('example') in the Matlab command line and
% then click anywhere within the axes boundary
% Note that this function will only work when no other Matlab buttonDown
% function is selected like for example the selection or zoom tools
%       
% This function is compatible with Matlab versions newer than R12

% PB - 2017
% Icon shape and idea for moving the reference line borrowed from Malcolm 
% Lidierth 'Data cursors for figure window' entry in the Matlab exchange

% TODO: 1) change text position calculation for axes with x in logarithmic 
%          or different scale, i.e. calculate text position based on screen
%          location rather than x value
%       2) Expand input error checks
%       3) update so it works with functions like plotyy
%       4) Modify user syntax from (it does not affect callback or internal call syntax):
%           - no arguments                    -> apply function to active axes
%           - 1 axes handle argument          -> apply function to axes given by handle
%           - action + ...                    -> main type of call where possible actions are 'example', 
%                                               and 'exact' (excludes internal use action options)
%           to
%           - no arguments                    -> apply function to active axes
%           - 1 axes handle argument          -> apply function to axes or all axes in figure depending on handle type
%           - action + ...                    -> should be showYs('example') or showYs(handle,'option','option value',...)
%                                                where options are 'exact', 'marker', 'markersize', 'markercolor',
%                                                'outputfunction' ('value', 'derivative', 'integral'), 'order' (an integer
%                                                which only applies to derivative and integral)
%       5) Update help above with supported functionality

% TODO: make this next variable axes dependant (i.e. 1 per axes using seappdata
persistent shownXIncreaseWarning

% REFORMAT CALLS TO ACCEPTABLE STANDARD IN FILE

    % EMPTY CALLS
	% Set the right value for the action if no input arguments

		if ~exist('action','var'), action='init'; end
        
    % HANDLE ONLY CALLS
	% If just one handle input argument (axes handle)
        if all(ishandle(action)) && strcmpi('axes',get(action,'type')) && isempty(varargin)
            theAxes = action;
            action  = 'init';
        end

    % FIGURE ONLY CALLS
	% If just one handle input argument (figure handle)
        if all(ishandle(action)) && strcmpi('figure',get(action,'type')) && isempty(varargin)
            theFig = action;
            allAxes = findobj(theFig,'Type','axes');
            allAxes = allAxes(~strcmpi(get(allAxes,'tag'),'legend'));
            for i=1:length(allAxes)
                showYs(allAxes(i));
            end
            return;
        end
        
    % CALLBACK CALLS
	% The first two inputs are set by Matlab when called by a callback
	% function. They are not explicitly used in the function and therefore
	% they are extracted from the input arguments in such case

		if ~ischar(action) && isempty(varargin{1}) && length(varargin)>1
			action   = varargin{2};
			varargin = varargin(3:end);
		end

        
% SELECT ACTION TO EXECUTE

switch lower(action)

    case 'example'
    
        % The call showYs('example') shows an example of the function
        figure
        subplot(311)
        x = 0:0.005:10;
        y1 = sin(x)/2+sin(3*x)+sin(7*x)/4;
        y1(200:800) = nan;
        plot(x,y1)
        hold on
        plot(x,(sin(2*x)/2+sin(3.5*x)+sin(6*x+2)/4),'r')
        plot(x,(sin(4*x)/3+sin(7.5*x)+sin(4*x+5)),'Color',[0.35 0.45 0.35])
        xlabel('Default: Interpolation/extrapolation (x values in x-axis)')
        ax1 = gca;
        showYs
        axis([-2 12 -2.5 2.5])
        
        subplot(312)
        x = 0:0.005:10;
        y1 = sin(x)/2+sin(3*x)+sin(7*x)/4;
        y1(200:800) = nan;
        plot(x,y1)
        hold on
        plot(x,(sin(2*x)/2+sin(3.5*x)+sin(6*x+2)/4),'r')
        plot(x,(sin(4*x)/3+sin(7.5*x)+sin(4*x+5)),'Color',[0.35 0.45 0.35])
        xlabel('Shows only exact values. All x-vectors are equal (x values in x-axis)')
        ax2 = gca;
        showYs
        showYs('exact')
        axis([-2 12 -2.5 2.5])
        
        subplot(313)
        x = 0:0.005:10;
        y1 = sin(x)/2+sin(3*x)+sin(7*x)/4;
        y1(200:800) = nan;
        plot(x(100:end),y1(100:end))
        hold on
        plot(x,(sin(2*x)/2+sin(3.5*x)+sin(6*x+2)/4),'r')
        plot(x,(sin(4*x)/3+sin(7.5*x)+sin(4*x+5)),'Color',[0.35 0.45 0.35])
        xlabel('Shows only exact values. NOT all x-vectors are equal (x-values in text box)')
        ax3 = gca;
        showYs
        showYs('exact')
        axis([-2 12 -2.5 2.5])
        
        showYs('link',[ax1 ax2 ax3])

    case 'init'
        
        % Note: this should not reset the linking
        
        % Max number of digits to show on text
        maxDig = 8;
        % Check if axes exist
        if ~exist('theAxes','var')
            theAxes = gca;
        end
        % Delete showYs created lines and text labels
        % if they currently exist
        hP = getappdata(theAxes,'showYsData_hP');
        hT = getappdata(theAxes,'showYsData_hT');
        hM = getappdata(theAxes,'showYsData_hM');
        if ishandle(hP), delete(hP); end
        if ~isempty(ishandle(hT)) && all(ishandle(hT)), delete(hT(:)); end
        if ~isempty(ishandle(hM)) && all(ishandle(hM)), delete(hM(:)); end
        % Choose all the lines in the curent axes
        lineHandles    = findobj(theAxes,'Type','Line');
        allLineHandles = lineHandles;
        % Iinitalize variables
        linesHandlesToIgnore = [];
        % Ignore lines with nonincreasing xs
        xTemp = get(lineHandles(1),'XData');
        allEqualPoints = 1;
        for i=1:length(lineHandles)
            xs = get(lineHandles(i),'XData');
            ys = get(lineHandles(i),'YData');
            zs = get(lineHandles(i),'ZData');
            if ~allEqualPoints || length(xTemp)~=length(xs) || any(xTemp~=xs), allEqualPoints = 0; end 
            % extract nonfinite values
            if isempty(zs)
                usePoints = isfinite(xs+ys);
            else
                usePoints = isfinite(xs+ys+zs);
            end
            xs = xs(usePoints);
            % Delete line from list if nonincreasing
            if (any(diff(xs)<=0) || isempty(xs))
                if isempty(shownXIncreaseWarning) || ~shownXIncreaseWarning
                    disp([mfilename ' : x values need to be strictly ' ...
                        'increasing. Ignoring non-compliant lines...'])
                    shownXIncreaseWarning = 1;
                end
                linesHandlesToIgnore = [linesHandlesToIgnore lineHandles(i)]; %#ok<AGROW>
            end
        end
        lineHandles = setdiff(lineHandles,linesHandlesToIgnore);
        % Set mouse click callbacks for the axes and lines
        set(theAxes,'ButtonDownFcn',{@showYs,'update',theAxes,lineHandles,[]});
        set(lineHandles,'ButtonDownFcn',{@showYs,'update',theAxes,lineHandles,[]})
        % Save application data in axes
        setappdata(theAxes,'showYsData_hP',nan);
        setappdata(theAxes,'showYsData_hT',num2cell(NaN(1,length(lineHandles))));
        setappdata(theAxes,'showYsData_visStr','');
        setappdata(theAxes,'showYsData_moveActive',0);
        setappdata(theAxes,'showYsData_lineHandles',lineHandles);
        setappdata(theAxes,'showYsData_maxDig',maxDig);
        setappdata(theAxes,'showYsData_allLineHandles',allLineHandles);
        setappdata(theAxes,'showYsData_hM',NaN(1,length(lineHandles)));
        setappdata(theAxes,'showYsData_allEqualPoints',allEqualPoints);
        setappdata(theAxes,'showYsData_scaled',0);
        setappdata(theAxes,'showYsData_scaledInRange',0);
        setappdata(theAxes,'showYsData_scaledOutRange',0);
        setappdata(theAxes,'showYsData_labels',0);
        setappdata(theAxes,'showYsData_labelsValues',0);
        setappdata(theAxes,'showYsData_labelsLabels',{});
        
        return; 
        
    case 'exact'
        
        if nargin==1, varargin{1}=gca; end
        theAxes        = varargin{1};
        setappdata(theAxes,'showYsData_exact',1);
        return;

    case 'link'
        
        linkedAxes = findobj(varargin{1},'type','axes');
        linkedAxes = linkedAxes(~strcmpi(get(linkedAxes,'tag'),'legend'));
        for i=1:length(linkedAxes)
            setappdata(linkedAxes(i),'showYsData_linkedAxes',linkedAxes);
        end
        return;
        
    case 'scaled'
        
        if length(varargin)~=3
            error('''scaled'' option needs to be called with 3 arguments: axes handle, original ranges and scaled ranges');
        else
            setappdata(varargin{1},'showYsData_scaled',1);
            setappdata(varargin{1},'showYsData_scaledInRange',varargin{2});
            setappdata(varargin{1},'showYsData_scaledOutRange',varargin{3});
        end
        return;
        
    case 'labels'
        
        if length(varargin)~=3
            error('''labels'' option needs to be called with 3 arguments: axes handle, values and labels');
        else
            setappdata(varargin{1},'showYsData_labels',1);
            setappdata(varargin{1},'showYsData_labelsValues',varargin{2});
            setappdata(varargin{1},'showYsData_labelsLabels',varargin{3});
        end
        return;
        
    case 'update'
        
        theAxes        = varargin{1};
        lineHandles    = varargin{2};
        currPoint      = varargin{3};
        
        % Check inputs
        
            if ishandle(theAxes) 
                isAxes=strcmpi(get(theAxes,'Type'),'axes'); 
            else
                isAxes=0; 
            end
            if ~isAxes
                error(' First argument should be a valid axes object');
            end
            % Give control to axes without changing figure status 
            set(get(theAxes,'parent'),'currentaxes',theAxes)
            
        % Refresh data if any line has dissapeared or changed
        % The total number of lines should be the same as when
        % showYs('init') was last called minus one for the vertical line
        % created by showYs
        
            if ishandle(getappdata(theAxes,'showYsData_hP'))
                isHhP = 1;
            else
                isHhP = 0;
            end
            lhM           = sum(ishandle(getappdata(theAxes,'showYsData_hM')));
            allLineHandles = getappdata(theAxes,'showYsData_allLineHandles');
            if ~all(ishandle(lineHandles)) || ...
               ~all(strcmpi('line',get(lineHandles,'type'))) || ...
               (length(findobj(theAxes,'Type','Line'))-isHhP-lhM)~=(length(allLineHandles))
                    hT = getappdata(theAxes,'showYsData_hT');
                    hP = getappdata(theAxes,'showYsData_hP');
                    hM = getappdata(theAxes,'showYsData_hM');
                    exact = getappdata(theAxes,'showYsData_exact');
                    for i=1:(length(lineHandles))
                        try %#ok<TRYNC>
                            delete(hT{i});
                            delete(hM(i));
                        end
                    end
                    try %#ok<TRYNC>
                        delete(hP)
                    end
                    showYs
                    setappdata(theAxes,'showYsData_exact',exact);
                    lineHandles = getappdata(theAxes,'showYsData_lineHandles');
                    showYs('update',theAxes,lineHandles,currPoint);
            end
            
        % get showYs variables
        
            hP             = getappdata(theAxes,'showYsData_hP');
            hT             = getappdata(theAxes,'showYsData_hT');
            visStr         = getappdata(theAxes,'showYsData_visStr');
            moveActive     = getappdata(theAxes,'showYsData_moveActive');
            maxDig         = getappdata(theAxes,'showYsData_maxDig');
            exact          = getappdata(theAxes,'showYsData_exact');
            hM             = getappdata(theAxes,'showYsData_hM');
            allEqualPoints = getappdata(theAxes,'showYsData_allEqualPoints');
            linkedAxes     = getappdata(theAxes,'showYsData_linkedAxes');
            scaled         = getappdata(theAxes,'showYsData_scaled');
            scaledInRange  = getappdata(theAxes,'showYsData_scaledInRange');
            scaledOutRange = getappdata(theAxes,'showYsData_scaledOutRange');
            labels         = getappdata(theAxes,'showYsData_labels');
            labelsValues   = getappdata(theAxes,'showYsData_labelsValues');
            labelsLabels   = getappdata(theAxes,'showYsData_labelsLabels');
            
        % if 'exact' is empty, set it to zero
        
            if isempty(exact), exact = 0; end
            
        % Set text font size

            textFontSize = 9;

        % Get mouse current point and axes limits    

        if isempty(currPoint)
            theX = get(theAxes,'CurrentPoint');
            theX = theX(1);
        else
            theX = currPoint;
        end
        theAxis  = axis;

        % Delete end part of label if created by this function

            theXLabel = get(get(theAxes,'XLabel'),'String');
            try
                pos = strfind(theXLabel,' -- x = ');
                theXLabel = theXLabel(1:pos(1)-1);
            catch %#ok<CTCH>
            end
            xlabel(theXLabel);

        % Switch visibility if necessary (when moveActive
        % is True the visibility will be kept at 'on')

            % This is a safety barrier just in case these two
            % variables are out of sync for whatever reason
            if strcmpi(visStr,'off') && moveActive, moveActive = 0; end
            % Do visibility calculations
            if strcmpi(visStr,'off') || isempty(visStr) || ...
                    ~ishandle(hP) || moveActive
                visStr = 'on';
            else
                visStr = 'off';
                set(hP,'Visible',visStr)
                setappdata(theAxes,'showYsData_visStr',visStr);
            end
            for i=1:length(lineHandles)
                if ishandle(hT{i})
                    set(hT{i},'Visible',visStr);
                end
                if ishandle(hM(i))
                    set(hM(i),'Visible',visStr);
                end
            end
            setappdata(theAxes,'showYsData_visStr',visStr);
            if strcmpi(visStr,'off') 
                % update linked axes
                if ~isempty(linkedAxes)
                    updateLinkedAxes(theAxes,linkedAxes,theX,moveActive)
                end
                return; 
            end

        % Plot vertical line

            holdState = ishold(theAxes);
            if ~holdState, hold on; end
            % % Comment next code line if automatic extension of
            % % axes is desired when axes is in automatic mode. 
            % This should be the last place where theX is defined
            theX = min(theAxis(2),max(theAxis(1),theX));
            if ~ishandle(hP) || isempty(hP)
                hP = line(theX*[1 1],[theAxis(3) theAxis(4)], ...
                    'Color',[0.85 0.6 0.6],'LineStyle','-','LineWidth',1);
                set(hP,'ButtonDownFcn',{@mouseDown,theAxes})
                set(gcf,'WindowButtonMotionFcn',{@mouseMove})
                set(gcf,'WindowButtonUpFcn',{@mouseUp})
            else
                hPYDataLims = get(hP,'YData');
                set(hP,'XData',theX*[1 1], ...
                       'YData',[min(hPYDataLims(1),theAxis(3)) ...
                                max(hPYDataLims(2),theAxis(4))], ...
                       'Visible',visStr);
            end
            if ~holdState, hold off; end
            setappdata(theAxes,'showYsData_hP',hP);

        % Find where to put the text labels

            try
                if theX<((theAxis(1)+theAxis(2))/2)
                    textX  = theX + 1/100*(theAxis(2)-theAxis(1));
                    textHA = 'left';
                else
                    textX  = theX - 1/100*(theAxis(2)-theAxis(1));
                    textHA = 'right';
                end
            catch %#ok<CTCH>
                textX  = theX;
                textHA = 'right';
            end

        % loop through lines to get the y-points and indicate if
        % values are extrapolated (including internal after elimination
        % of non-finite values)

            isVisible  = logical((1:length(lineHandles))*0);
            ysVect     = (1:length(lineHandles))*inf;
            for i=1:length(lineHandles)
                xs = get(lineHandles(i),'XData');
                ys = get(lineHandles(i),'YData');
                % Calculate values for interpolated and exact
                if length(ys)>1 && ~exact
                    usePoints = isfinite(xs+ys);
                    ixCheck   = unique([find(xs<theX,1,'last')...
                                        find(xs>theX,1,'first')...
                                        find(xs==theX,1,'first')]);
                    wasNotFinite = ~all(isfinite(xs(ixCheck)+ys(ixCheck)));
                    xs  = xs(usePoints);
                    ys  = ys(usePoints);
                    % Calculate y point
                    theY = interp1(xs,ys,theX,'linear','extrap');
                    % Convert x and y positions to characters
                    strX = num2str(sigDig(theX,maxDig),'%8g');
                    % Modify ys if scaled option selected
                    if scaled
                        theYToStr = interp1(scaledInRange,scaledOutRange,theY,'linear','extrap');
                    else
                        theYToStr = theY;
                    end
                    strY = num2str(sigDig(theYToStr,maxDig),'%8g');
                    tBoxLineW = 1;
                    if theX>max(xs) || theX<min(xs) || wasNotFinite
                        styleT = ':';
                        angleT = 'italic';
                    else
                        styleT = '-';
                        angleT = 'normal';
                    end
                    % theX corresponds to the text/line positions, thisX
                    % to the markerPos/x-value
                    thisX = theX;
                elseif length(ys)>1 && exact
                    [~,ixMinDist] = min(abs(xs-theX));
                    thisX  = xs(ixMinDist);
                    theY   = ys(ixMinDist);
                    styleT = '-';
                    angleT = 'normal';
                    tBoxLineW = 2;
                    % Modify ys if scaled option selected
                    if scaled
                        theYToStr = interp1(scaledInRange,scaledOutRange,theY,'linear','extrap');
                    else
                        theYToStr = theY;
                    end
                    % Convert x and y positions to characters
                    % All points are equal
                    if allEqualPoints
                        strX = num2str(sigDig(thisX,maxDig),'%8g');
                        strY = num2str(sigDig(theYToStr,maxDig),'%8g');
                    else
                        % Not all points are equal
                        % Lines have different x's
                        strY = ['{' num2str(sigDig(thisX,maxDig),'%8g') ...
                              '; ' num2str(sigDig(theYToStr,maxDig),'%8g') '}'];
                    end
                    % If y = nan or +/-Inf leave the string as found above
                    % but set text position height at closest valid height
                    % theX corresponds to the text/line positions, thisX
                    % to the markerPos/x-value
                    usePoints        = isfinite(xs+ys);
                    [~,ixMinDist] = min(abs(xs(usePoints)-theX));
                    theY = ys(usePoints);
                    theY = theY(ixMinDist);
                end
                if labels
                    strY = labelsLabels{find(labelsValues>=theY,1,'first')};
                end
                clear ys
                isLineVisible = strcmpi(get(lineHandles(i),'Visible'),'on');
                lineCol = get(lineHandles(i),'Color');
                % Create or update text boxes
                if isnan(hT{i})
                    BackCol = [0.95 0.98 0.95];
                    if sum(get(theAxes,'color'))<1.5
                        BackCol = get(theAxes,'color')+0.05*[1 1 1];
                    end
                        hT{i} = text(textX,theY,1,strY,'HorizontalAlignment',textHA,'VerticalAlignment','middle',... 
                        'FontWeight','normal','FontSize',textFontSize,'Color',lineCol);
                        set(hT{i},'BackgroundColor',BackCol,'EdgeColor',[0.85 0.95 0.85]*0.6,'LineStyle',styleT,...
                            'LineWidth',tBoxLineW,'FontAngle',angleT); 
                else
                    set(hT{i},'Position',[textX theY 1],'HorizontalAlignment',textHA,'String', ...
                        strY,'Visible',visStr,'LineStyle',styleT,'Color',lineCol,...
                        'LineWidth',tBoxLineW,'FontAngle',angleT);
                end
                % Create or update marker
                lWidth = get(lineHandles(i),'linewidth');
                if isnan(hM(i))
                    hM(i) = line(thisX,theY,'marker','.','MarkerSize',lWidth+10,'Color',lineCol);
                else
                    set(hM(i),'XData',thisX,'YData',theY,'Color',lineCol)
                end
                % Set visibilities of text boxes and markers
                if theY>(theAxis(3)+1/1000*(theAxis(4)-theAxis(3))) && theY<(theAxis(4)-1/1000*(theAxis(4)-theAxis(3)))
                    set(hT{i},'Visible',visStr)
                    set(hM(i),'visible',visStr)
                else
                    set(hT{i},'Visible','off')
                    set(hM(i),'visible','off')
                end
                isVisible(i) = strcmpi(get(hT{i},'Visible'),'on');
                ysVect(i)    = theY;
                if ~isLineVisible 
                    set(hT{i},'visible','off'); 
                    set(hM(i),'visible','off');
                end
           end

        % The bit that follows tries to sort the labels so they do not overlap.
        % There are some specific cases where this fails. It still needs some work

            extentText = zeros(length(lineHandles),2);
            for i=1:length(lineHandles)
                exti = get(hT{i},'Extent');                  % [left bottom width height]
                extentText(i,:) = [exti(2) exti(2)+exti(4)]; % [bottom top]
                upOnly   = 0; % to avoid label moving in more than one direction
                downOnly = 0; % to avoid label moving in more than one direction
                for j=1:(i-1)
                    if isVisible(i) && isVisible(j)
                        done = 0; % only execute one of the 'if's below
                        if (exti(2)<=extentText(j,2) && exti(2)>=extentText(j,1)) || (ysVect(i)<=extentText(j,2) && ysVect(i)>=extentText(j,1))
                            if downOnly
                                set(hT{i},'Position',[textX extentText(j,1)-exti(4)/2 0])
                            else
                                set(hT{i},'Position',[textX extentText(j,2)+exti(4)/2 0])
                                upOnly = 1;
                            end
                            done = 1;
                        end
                        if (((exti(2)+exti(4))>=extentText(j,1) && (exti(2)+exti(4))<=extentText(j,2)) || ((ysVect(i)>=extentText(j,1) && (ysVect(i)<=extentText(j,2))))) && done==0
                            if upOnly
                                set(hT{i},'Position',[textX extentText(j,2)+exti(4)/2 0])
                            else
                                set(hT{i},'Position',[textX extentText(j,1)-exti(4)/2 0])
                                downOnly = 1;
                            end
                        end
                        exti = get(hT{i},'Extent');
                        extentText(i,:) = [exti(2) exti(2)+exti(4)];
                    end
                end
            end

        % Put the labels in the correct increasing order

            for i=1:length(lineHandles)
                for j=1:(i-1)
                    if (extentText(i,1)>extentText(j,1)) && (ysVect(i)<ysVect(j)) && isVisible(i) && isVisible(j)
                        posi = get(hT{i},'Position');
                        posj = get(hT{j},'Position');
                        set(hT{i},'Position',posj)
                        set(hT{j},'Position',posi)
                    end
                end
            end

        % Update the xlabel

            if ~exact || allEqualPoints
                theLabel = get(get(theAxes,'XLabel'),'String');
                if iscell(theLabel), theLabel=theLabel{1}; end
                xlabel([theLabel ' -- x = ' strX ' --']);
            end

        % update linked axes

        if ~isempty(linkedAxes)
            updateLinkedAxes(theAxes,linkedAxes,theX,moveActive)
        end

        % Update appdata

            setappdata(theAxes,'showYsData_hT',hT);
            setappdata(theAxes,'showYsData_hM',hM)    
end
    
% ********************************************************
% *****************  OTHER FUNCTIONS *********************
% ********************************************************

function mouseDown(handle,events,theAxes) %#ok<INUSL>

moveActive = getappdata(theAxes,'showYsData_moveActive');
if isempty(moveActive) || ~moveActive
    CData=[ NaN	NaN	NaN	NaN	NaN	2	2	2	2	2	NaN	NaN	NaN	NaN	NaN	NaN;...
            NaN	NaN	NaN	NaN	NaN	2	1	2	1	2	NaN	NaN	NaN	NaN	NaN	NaN;...
            NaN	NaN	NaN	NaN	NaN	2	1	2	1	2	NaN	NaN	NaN	NaN	NaN	NaN;...
            NaN	NaN	NaN	NaN	2	2	1	2	1	2	2	NaN	NaN	NaN	NaN	NaN;...
            NaN	NaN	NaN	2	1	2	1	2	1	2	1	2	NaN	NaN	NaN	NaN;...
            NaN	NaN	2	1	1	2	1	2	1	2	1	1	2	NaN	NaN	NaN;...
            NaN	2	1	1	1	1	1	2	1	1	1	1	1	2	NaN	NaN;...
            2	1	1	1	1	1	1	2	1	1	1	1	1	1	2	NaN;...
            NaN	2	1	1	1	1	1	2	1	1	1	1	1	2	NaN	NaN;...
            NaN	NaN	2	1	1	2	1	2	1	2	1	1	2	NaN	NaN	NaN;...
            NaN	NaN	NaN	2	1	2	1	2	1	2	1	2	NaN	NaN	NaN	NaN;...
            NaN	NaN	NaN	NaN	2	2	1	2	1	2	2	NaN	NaN	NaN	NaN	NaN;...
            NaN	NaN	NaN	NaN	NaN	2	1	2	1	2	NaN	NaN	NaN	NaN	NaN	NaN;...
            NaN	NaN	NaN	NaN	NaN	2	1	2	1	2	NaN	NaN	NaN	NaN	NaN	NaN;...
            NaN	NaN	NaN	NaN	NaN	2	2	2	2	2	NaN	NaN	NaN	NaN	NaN	NaN;...
            NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN];
        
    setappdata(theAxes,'showYsData_moveActive',1);
    % Activate the cursor pointer
    set(gcf,'PointerShapeCData',CData);
    set(gcf,'Pointer','custom');
    set(gcf,'PointerShapeHotSpot',[8 8]);
else
    setappdata(theAxes,'showYsData_moveActive',0);
    set(gcf, 'Pointer', 'arrow');
end


% ********************************************************
    
function mouseMove(handle,events) %#ok<INUSD>

    theAxes = gca;
    lineHandles = getappdata(theAxes,'showYsData_lineHandles');
    moveActive  = getappdata(theAxes,'showYsData_moveActive');
    if ~isempty(moveActive) && moveActive
        theX = get(theAxes,'CurrentPoint');
        theX = theX(1);
        showYs('update',theAxes,lineHandles,theX);
    end
 
% ********************************************************

function mouseUp(handle,events) %#ok<INUSD>

    theAxes = gca;
    moveActive = getappdata(theAxes,'showYsData_moveActive');
    if isempty(moveActive) || ~moveActive
        set(gcf, 'Pointer', 'arrow');
    end

% ********************************************************

function outVal = sigDig(inVal,n)

% Round to given number of significant digits 
    
    if isempty(inVal), outVal=NaN; return; end
    if 0==inVal || isnan(inVal) || isinf(inVal)
        outVal = inVal; 
        return; 
    end
	% Most Sign Digit
	MSD = ceil(log10(abs(inVal)));
	% rounding factor
	dec = 10^(MSD-n);
	outVal = dec*round(inVal/dec);
    
 % ********************************************************

function updateLinkedAxes(theAxes,linkedAxes,theX,moveActive)

    linkedAxes = setdiff(linkedAxes,theAxes);
    for i=1:length(linkedAxes)
        % Ignore non-existing axes
        if ~ ishandle(linkedAxes(i)) || ~strcmpi('axes',get(linkedAxes(i),'type')), continue; end
        % reset linked axis information for all other axes linked to this
        % one so when showYs is called on those we do not have an infinite
        % loop of those calling this one ans so on
        thisLinkedAxes = getappdata(linkedAxes(i),'showYsData_linkedAxes');
        setappdata(linkedAxes(i),'showYsData_linkedAxes',[]);
        % Get line handles to update on linked axes
        linkedLineHandles = getappdata(linkedAxes(i),'showYsData_lineHandles');
        % Set same moveActive value as current axes
        setappdata(linkedAxes(i),'showYsData_moveActive',moveActive);
        % And call showYs on other axes
        showYs('update',linkedAxes(i),linkedLineHandles,theX);
        % Restore info about linked axes on axes just updated
        setappdata(linkedAxes(i),'showYsData_linkedAxes',thisLinkedAxes);
    end
    set(gcf,'currentaxes',theAxes)

   
    
    