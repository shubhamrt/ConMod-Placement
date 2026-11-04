% Figure 2: study plots and their vegetation structure.
% Shubham Tiwari, 2026

clear; clc; close all;

%% paths
root = fullfile(fileparts(mfilename('fullpath')),'..');
ddir = fullfile(root,'data'); odir = fullfile(root,'output');
if ~exist(odir,'dir'), mkdir(odir); end
f_dir = odir;
all_file = fullfile(ddir,'aim_locations.csv');
sel_file = fullfile(ddir,'plots_1500.csv');
gap_file = fullfile(ddir,'gap_heights.csv');
EXPORT_DPI = 300;

%% style
FT='Helvetica'; FS_t=11; FS_l=11; LW_ax=1.2;   % 11 everywhere; legends use FS_t-1 = 10
set(groot,'defaultAxesFontName',FT,'defaultTextFontName',FT, ...
          'defaultAxesFontSize',FS_t,'defaultTextFontSize',FS_t);
COL  = struct('grass',[0.18 0.63 0.37],'mixed',[0.19 0.51 0.74],'shrub',[0.90 0.63 0.12]);
GREY = [0.66 0.66 0.66]; STATE=[0.60 0.60 0.60];
types={'grass','mixed','shrub'}; labels={'Grass','Mixed','Shrub'};

%% load
allp = readtable(all_file,'TextType','string');
sel  = readtable(sel_file,'TextType','string');
XL=[-125 -100]; YL=[31 49];

gapT = readtable(gap_file,'TextType','string');
[gg,pk] = findgroups(gapT.PrimaryKey);
gmean   = splitapply(@mean,double(gapT.length_m),gg);
[tf,loc] = ismember(sel.PrimaryKey,pk);
sel.gapmean = nan(height(sel),1);
sel.gapmean(tf) = gmean(loc(tf));
fprintf('  mean gap length matched for %d of %d plots\n',sum(tf),height(sel));

have_states=false;
try, st=shaperead('usastatelo','UseGeoCoords',true); have_states=true;
catch, fprintf('  (state outlines skipped - Mapping Toolbox not found)\n'); end

%% figure
fig=figure('Color','w','Units','pixels','Position',[20 20 1500 1050],'Name','Figure 2');

axA=axes('Units','normalized','Position',[0.045 0.070 0.545 0.880]); hold(axA,'on');
if have_states
    for i=1:numel(st)
        if isempty(st(i).Lat), continue; end
        plot(axA,st(i).Lon,st(i).Lat,'-','Color',STATE,'LineWidth',0.7,'HandleVisibility','off');
    end
end
scatter(axA,allp.LON,allp.LAT,3,'o','filled', ...
    'MarkerFaceColor',[0.55 0.55 0.55], ...
    'MarkerFaceAlpha',0.35, ...
    'MarkerEdgeColor','none', ...
    'HandleVisibility','off');

for k=1:3
    t=types{k};
    d=sel(sel.site_type==t,:);
    
    edgeCol = COL.(t) * 0.58;
    
    scatter(axA,d.LON,d.LAT,20,'o','filled', ...
        'MarkerFaceColor',COL.(t), ...
        'MarkerFaceAlpha',0.88, ...
        'MarkerEdgeColor',edgeCol, ...
        'LineWidth',0.35, ...
        'HandleVisibility','off');
end
xlim(axA,XL); ylim(axA,YL); daspect(axA,[1 cosd(mean(YL)) 1]);
axA.LineWidth=LW_ax; axA.Layer='top'; box(axA,'on');
axA.XTick=-125:5:-100; axA.YTick=30:5:50;
axA.XTickLabel=compose('%d\\circ',abs(axA.XTick))+"W";
axA.YTickLabel=compose('%d\\circ',axA.YTick)+"N";
set(gca,'fontsize',FS_l-1)
grid(axA,'on'); axA.GridColor=[0.85 0.85 0.85]; axA.GridAlpha=0.7;
xlabel(axA,'Longitude'); ylabel(axA,'Latitude');
hTitle = title(axA, ...
    'a. Spatial distribution of study plots over the western United States', ...
    'FontSize',FS_l, ...
    'FontWeight','bold');

hTitle.Position(2) = 49.2;

nax=XL(1)+0.05*diff(XL); nay=YL(2)-0.13*diff(YL); nl=diff(YL)*0.06;
patch(axA,[nax nax-nl*0.18 nax],[nay+nl nay nay+nl*0.4],[0.1 0.1 0.1],'EdgeColor','none','HandleVisibility','off');
patch(axA,[nax nax+nl*0.18 nax],[nay+nl nay nay+nl*0.4],[0.95 0.95 0.95],'EdgeColor',[0.15 0.15 0.15],'LineWidth',0.6,'HandleVisibility','off');
text(axA,nax,nay+nl*1.35,'N','FontSize',FS_l,'FontWeight','bold','HorizontalAlignment','center');

ng=sum(sel.site_type=="grass"); nm=sum(sel.site_type=="mixed"); ns=sum(sel.site_type=="shrub");
hG=scatter(axA,NaN,NaN,40,'o','filled','MarkerFaceColor',COL.grass,'MarkerEdgeColor','k','LineWidth',0.3);
hM=scatter(axA,NaN,NaN,40,'o','filled','MarkerFaceColor',COL.mixed,'MarkerEdgeColor','k','LineWidth',0.3);
hS=scatter(axA,NaN,NaN,40,'o','filled','MarkerFaceColor',COL.shrub,'MarkerEdgeColor','k','LineWidth',0.3);
hB=scatter(axA,NaN,NaN,10,'o','filled','MarkerFaceColor',GREY,'MarkerEdgeColor','none');
lg=legend(axA,[hG hM hS hB], ...
    {sprintf('Grass (n = %d)',ng),sprintf('Mixed (n = %d)',nm),sprintf('Shrub (n = %d)',ns), ...
     sprintf('All AIM plots (n = %s)',addcommas(height(allp)))}, ...
    'FontSize',FS_t-1,'FontName',FT,'Location','southwest');
lg.Box='off'; lg.Color='none'; lg.ItemTokenSize=[14 14];

axB=axes('Units','normalized','Position',[0.640 0.6900 0.220 0.250]);
hold(axB,'on');

boxbytype(axB,sel,'gapmean',types,labels,COL);

ylabel(axB,'Mean canopy gap length (m)');

yl=prctile(sel.gapmean(~isnan(sel.gapmean)),99.5);
ylim(axB,[0 max(1.5,ceil(yl*2)/2)]);
set(gca,'fontsize',FS_l-1)
title(axB,'b. Canopy gap size', ...
    'FontWeight','bold','FontSize',FS_t);

axC=axes('Units','normalized','Position',[0.640 0.380 0.220 0.250]); 
hold(axC,'on');

boxbytype(axC,sel,'cover',types,labels,COL);

ylabel(axC,'Total foliar cover (%)'); 
ylim(axC,[0 100]);
set(gca,'fontsize',FS_l-1)
title(axC,'c. Vegetation cover', ...
    'FontWeight','bold','FontSize',FS_t);

axD=axes('Units','normalized','Position',[0.640 0.06 0.220 0.250]); 
hold(axD,'on');

boxbytype(axD,sel,'height',types,labels,COL);

ylabel(axD,'Vegetation height (cm)');

yl=prctile(sel.height(~isnan(sel.height)),99.5); 
ylim(axD,[0 max(20,ceil(yl/10)*10)]);
set(gca,'fontsize',FS_l-1)
title(axD,'d. Vegetation height', ...
    'FontWeight','bold','FontSize',FS_t);

fontname(fig,FT);
tmp=[tempname '.png']; exportgraphics(fig,tmp,'Resolution',EXPORT_DPI);
img=imread(tmp); img=padarray(img,[20 20],255,'both');
imwrite(img,fullfile(f_dir,'Figure2_study_plots.png'));
fprintf('Saved: figures/Fig1_PlotDistribution.png\n');

%% helpers
function boxbytype(ax,sel,col,types,labels,COL)

    hold(ax,'on');

    rng(42,'twister');

    for k=1:numel(types)

        v = sel.(col)(sel.site_type==types{k});
        v = v(~isnan(v) & isfinite(v));

        if isempty(v)
            continue;
        end

        c = COL.(types{k});
        cDark = c * 0.62;

        if exist('ksdensity','file') == 2

            [f,xi] = ksdensity(v,'NumPoints',200);

        else

            nBins = max(15,min(35,round(sqrt(numel(v)))));

            edges = linspace(min(v),max(v),nBins+1);

            [N,E] = histcounts(v,edges,'Normalization','pdf');

            mid = (E(1:end-1)+E(2:end))/2;

            N = movmean(N,3);

            xi = linspace(min(v),max(v),200);

            f = interp1(mid,N,xi,'pchip',0);

        end

        f  = f(:)';
        xi = xi(:)';

        if max(f) > 0
            halfWidth = 0.32 * f ./ max(f);

            patch(ax, ...
                [k-halfWidth, fliplr(k+halfWidth)], ...
                [xi, fliplr(xi)], ...
                c, ...
                'FaceAlpha',0.14, ...
                'EdgeColor','none', ...
                'HandleVisibility','off');
        end

        nShow = min(150,numel(v));

        idx = randperm(numel(v),nShow);

        xJitter = k + (rand(nShow,1)-0.5)*0.28;

        scatter(ax,xJitter,v(idx),7,'o','filled', ...
            'MarkerFaceColor',c, ...
            'MarkerFaceAlpha',0.14, ...
            'MarkerEdgeColor','none', ...
            'HandleVisibility','off');

        q = prctile(v,[10 25 50 75 90]);

        q10 = q(1);
        q25 = q(2);
        q50 = q(3);
        q75 = q(4);
        q90 = q(5);

        plot(ax,[k k],[q10 q90],'-', ...
            'Color',cDark, ...
            'LineWidth',1.2, ...
            'HandleVisibility','off');

        plot(ax,[k-0.07 k+0.07],[q10 q10],'-', ...
            'Color',cDark, ...
            'LineWidth',1.2, ...
            'HandleVisibility','off');

        plot(ax,[k-0.07 k+0.07],[q90 q90],'-', ...
            'Color',cDark, ...
            'LineWidth',1.2, ...
            'HandleVisibility','off');

        boxWidth = 0.28;

        boxFill = c + (1-c)*0.72;

        patch(ax, ...
            [k-boxWidth/2 k+boxWidth/2 k+boxWidth/2 k-boxWidth/2], ...
            [q25 q25 q75 q75], ...
            boxFill, ...
            'FaceAlpha',0.92, ...
            'EdgeColor',c, ...
            'LineWidth',1.25, ...
            'HandleVisibility','off');

        plot(ax, ...
            [k-boxWidth/2 k+boxWidth/2], ...
            [q50 q50], ...
            '-', ...
            'Color',cDark, ...
            'LineWidth',2.0, ...
            'HandleVisibility','off');

    end

    ax.XTick = 1:numel(types);
    ax.XTickLabel = labels;

    xlim(ax,[0.4 numel(types)+0.6]);

    ax.LineWidth = 1.1;
    ax.Layer = 'top';

    box(ax,'on');

    ax.YGrid = 'on';
    ax.XGrid = 'off';

    ax.GridColor = [0.88 0.88 0.88];
    ax.GridAlpha = 0.45;

end
function s=addcommas(n)
    s=regexprep(num2str(n),'\d{1,3}(?=(\d{3})+(?!\d))','$0,');
end
