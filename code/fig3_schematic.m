% Figure 3: schematic of the four placement strategies.
% Shubham Tiwari, 2026

clear; clc;
odir = fullfile(fileparts(mfilename('fullpath')),'..','output');
if ~exist(odir,'dir'), mkdir(odir); end

%% constants
FONT='Arial'; FS=11; FS_SM=10; TXT=[0.10 0.10 0.10];
MIN_SUB=0.25;
CM_H=0.30;             % drawn ConMod height (m)
N=4;                   % structures per plot

COL.shrub=[0.38 0.60 0.32]; COL.grass=[0.68 0.82 0.22]; COL.soil=[0.88 0.82 0.66];
COL.gap=[0.93 0.88 0.75];  COL.conmod=[0.12 0.18 0.42]; COL.sel=[0.99 0.94 0.82];
COL.selEdge=[0.80 0.65 0.35]; COL.bracket=[0.55 0.40 0.15]; COL.grid=[0.55 0.55 0.58];

%% baseline geometry
GAPS = [ 0.7,  6.7, 0.50;    % long, shrub-bordered   (6.0 m, scaled 12.0)
         7.5, 10.4, 0.50;    % medium, shrub-bordered (2.9 m, scaled  5.8)
        11.3, 13.8, 0.15;    % grass-bordered         (2.5 m, scaled 16.7)
        14.6, 16.9, 0.15;    % grass-bordered         (2.3 m, scaled 15.3)
        17.7, 19.8, 0.15;    % grass-bordered         (2.1 m, scaled 14.0)
        20.6, 22.6, 0.15];   % grass-bordered         (2.0 m, scaled 13.3)
T = 23.3;

veg = [ 0.0,  0.7, 0.50, 1;
        6.7,  7.5, 0.50, 1;
       10.4, 11.0, 0.50, 1;
       11.0, 11.3, 0.15, 2;
       13.8, 14.6, 0.15, 2;
       16.9, 17.7, 0.15, 2;
       19.8, 20.6, 0.15, 2;
       22.6, 23.3, 0.15, 2];

%% placements
POS.cellgrid = split_cellgrid(GAPS(:,1:2), N, T);
POS.targeted = split_targeted(GAPS(:,1:2), N, MIN_SUB);
POS.scaled   = split_scaled  (GAPS,        N, MIN_SUB);
POS.prop     = split_prop    (GAPS(:,1:2), N, MIN_SUB);

%% figure
fig=figure('Units','inches','Position',[0.5 0.5 11.0 9.0],'Color','w');
tl=tiledlayout(fig,5,1,'TileSpacing','tight','Padding','compact');

panel = { '(a)  Baseline: vegetation and gap structure',                       'baseline';
          '(b)  Cell-grid: one structure per cell (largest within-cell gap)',  'cellgrid';
          '(c)  Largest-gap: longest gap first',                               'targeted';
          '(d)  Scaled gap: largest gap length / bordering vegetation height (x/h)', 'scaled';
          '(e)  Proportional: structures per gap \propto gap length',          'prop'};

find_gap=@(x) find(x>=GAPS(:,1) & x<=GAPS(:,2),1);

for p=1:5
    ax=nexttile(tl); hold(ax,'on');
    strat=panel{p,2}; is_base=strcmp(strat,'baseline');
    pos=[]; if ~is_base, pos=POS.(strat); end
    sel=arrayfun(@(x) find_gap(x), pos, 'UniformOutput',false);
    sel=unique([sel{:}]);

    fill(ax,[0 T T 0 0],[-0.07 -0.07 0 0 -0.07],COL.soil,'EdgeColor','none','HandleVisibility','off');

    for k=1:size(GAPS,1)
        g0=GAPS(k,1); g1=GAPS(k,2);
        if any(sel==k)
            fill(ax,[g0 g1 g1 g0],[0 0 0.80 0.80],COL.sel,'EdgeColor',COL.selEdge, ...
                 'LineStyle','--','LineWidth',0.8,'FaceAlpha',0.85,'HandleVisibility','off');
        else
            fill(ax,[g0 g1 g1 g0],[0 0 0.80 0.80],COL.gap,'EdgeColor','none', ...
                 'FaceAlpha',0.50,'HandleVisibility','off');
        end
    end

    if strcmp(strat,'cellgrid')
        for c=1:N-1
            plot(ax,[c*T/N c*T/N],[-0.07 0.92],':','Color',COL.grid,'LineWidth',0.9,'HandleVisibility','off');
        end
        for c=1:N
            text(ax,(c-0.5)*T/N,0.90,sprintf('cell %d',c),'FontSize',FS_SM, ...
                 'HorizontalAlignment','center','Color',COL.grid,'FontName',FONT);
        end
    end

    theta=linspace(0,pi,80);
    for v=1:size(veg,1)
        x1=veg(v,1); x2=veg(v,2); h=veg(v,3); tp=veg(v,4); xc=(x1+x2)/2; wv=x2-x1;
        fade=~is_base;
        if tp==1
            xv=xc+(wv/2)*cos(theta); yv=h*sin(theta);
            fc=COL.shrub; ec=COL.shrub*0.65; if fade, fc=fc*0.82+0.18; ec=ec*0.7+0.3; end
            fill(ax,[xv,xv(end),xv(1)],[yv,0,0],fc,'EdgeColor',ec,'LineWidth',0.6,'HandleVisibility','off');
        else
            fc=COL.grass; if fade, fc=fc*0.82+0.18; end
            for b=1:5
                frac=b/6; bx=x1+frac*wv; lean=(frac-0.5)*wv*0.4; bh=h*(0.8+0.2*sin(pi*frac));
                fill(ax,[bx-0.03,bx+0.03,bx+lean+0.02,bx+lean-0.02],[0,0,bh,bh],fc,'EdgeColor','none','HandleVisibility','off');
            end
        end
    end

    plot(ax,[0 T],[0 0],'-','Color',[0.45 0.30 0.12],'LineWidth',1.1,'HandleVisibility','off');

    if ~is_base
        for k=1:numel(pos)
            xc=pos(k);
            plot(ax,[xc xc],[0 CM_H],'-','Color',COL.conmod,'LineWidth',2.6,'HandleVisibility','off');
            plot(ax,[xc-0.26 xc+0.26],[CM_H CM_H],'-','Color',COL.conmod,'LineWidth',3.0,'HandleVisibility','off');
            text(ax,xc,CM_H+0.12,sprintf('%d',k),'FontSize',FS_SM,'HorizontalAlignment','center', ...
                 'FontWeight','bold','Color',TXT,'FontName',FONT);
        end
    end

    if is_base
        lbl={'6.0 m','2.9 m','2.5 m','2.3 m','2.1 m','2.0 m'}; y0=0.66;
        xh=(GAPS(:,2)-GAPS(:,1))./GAPS(:,3);   % scaled gap x/h shown under each length
        for k=1:size(GAPS,1)
            xL=GAPS(k,1); xR=GAPS(k,2); xm=(xL+xR)/2;
            plot(ax,[xL xR],[y0 y0],'-','Color',COL.bracket,'LineWidth',0.7,'HandleVisibility','off');
            plot(ax,[xL xL],[y0-0.03 y0],'-','Color',COL.bracket,'LineWidth',0.7,'HandleVisibility','off');
            plot(ax,[xR xR],[y0-0.03 y0],'-','Color',COL.bracket,'LineWidth',0.7,'HandleVisibility','off');
            text(ax,xm,y0+0.05,lbl{k},'FontSize',FS_SM,'HorizontalAlignment','center','Color',TXT,'FontName',FONT);
            text(ax,xm,0.90,sprintf('x/h = %.0f',xh(k)),'FontSize',FS_SM,'HorizontalAlignment','center','Color',TXT,'FontName',FONT);
        end
        wy=0.34; wc=[0.25 0.35 0.68];
        plot(ax,[3 4.4],[wy wy],'-','Color',wc,'LineWidth',1.6,'HandleVisibility','off');
        plot(ax,4.4,wy,'>','Color',wc,'MarkerFaceColor',wc,'MarkerSize',6,'HandleVisibility','off');
        text(ax,2.7,wy,'Wind (U)','FontSize',FS,'FontWeight','bold','Color',wc,'HorizontalAlignment','right','FontName',FONT);
        hR=plot(ax,NaN,NaN,'-','Color',COL.conmod,'LineWidth',2.6);
        hT=fill(ax,NaN,NaN,COL.sel,'EdgeColor',COL.selEdge,'LineStyle','--');
        hS=fill(ax,NaN,NaN,COL.shrub,'EdgeColor',COL.shrub*0.65);
        hG=fill(ax,NaN,NaN,COL.grass,'EdgeColor','none');
        hB=fill(ax,NaN,NaN,COL.gap,'EdgeColor','none');
        lg=legend(ax,[hR hT hS hG hB], ...
            {'Roughness structure','Treated gap','Shrub','Grass','Bare gap'}, ...
            'Orientation','horizontal','FontSize',FS_SM,'Box','on', ...
            'EdgeColor',[0.85 0.85 0.85],'FontName',FONT);
        lg.TextColor=TXT;
        lg.Layout.Tile='north';
    end

    ty=0.965; if p<=2, ty=1.00; end      % (a) and (b) titles sit a little higher
    text(ax,0.010,ty,panel{p,1},'Units','normalized','FontSize',FS,'FontWeight','bold', ...
         'VerticalAlignment','top','Color',TXT,'FontName',FONT,'BackgroundColor','w','Margin',1);

    ax.XLim=[-0.5 T+0.5]; ax.YLim=[-0.10 1.20];   % headroom so labels sit below the panel title
    ax.YTick=[0 0.25 0.5]; ax.YTickLabel={'0','0.25','0.5'};
    ax.XTick=0:5:T; ax.FontSize=FS; ax.FontName=FONT; ax.Box='off'; ax.TickDir='out';
    ax.XColor=[0.3 0.3 0.3]; ax.YColor=[0.3 0.3 0.3]; ax.Layer='top'; ax.LineWidth=0.8;
    if p<5, ax.XTickLabel={}; else, xlabel(ax,'Distance along transect (m)','FontSize',FS,'FontName',FONT); end
    ylabel(ax,'Height (m)','FontSize',FS,'FontName',FONT);
    hold(ax,'off');
end

title(tl,sprintf('Placement strategies for restoration structures  (N = %d; each structure divides a gap; minimum sub-gap 0.25 m)',N), ...
      'FontSize',FS+1,'FontWeight','bold','FontName',FONT,'Color',TXT);

m = 0.1;
set(fig,'Units','inches'); P = get(fig,'Position');
set(fig,'PaperUnits','inches', ...
        'PaperSize',[P(3)+2*m, P(4)+2*m], ...
        'PaperPosition',[m, m, P(3), P(4)], ...
        'InvertHardcopy','off');           % keep the white background in the margin
print(fig,fullfile(odir,'Figure3_placement_schematic.pdf'),'-dpdf','-vector');
print(fig,fullfile(odir,'Figure3_placement_schematic.png'),'-dpng','-r300');
fprintf('Saved Figure 3\n');

%% placement rules
function pos = split_targeted(g, n, MINSUB)
    P=g; pos=[];
    for i=1:n
        len=P(:,2)-P(:,1); [mx,idx]=max(len);
        if mx < 2*MINSUB, break; end
        a=P(idx,1); b=P(idx,2); m=(a+b)/2; pos(end+1)=m; %#ok<AGROW>
        P(idx,:)=[]; P=[P; a m; m b];
    end
end

function pos = split_scaled(g, n, MINSUB)
    P=g(:,1:3); pos=[];
    for i=1:n
        len=P(:,2)-P(:,1); ratio=len./P(:,3); ratio(len<2*MINSUB)=-inf;
        [mx,idx]=max(ratio);
        if ~isfinite(mx), break; end
        a=P(idx,1); b=P(idx,2); H=P(idx,3); m=(a+b)/2; pos(end+1)=m; %#ok<AGROW>
        P(idx,:)=[]; P=[P; a m H; m b H];
    end
end

function pos = split_prop(g, n, MINSUB)
    len=g(:,2)-g(:,1); tot=sum(len); raw=len/tot*n;
    cap=max(0,floor(len/MINSUB)-1); base=min(floor(raw),cap);
    rem=n-sum(base); [~,ord]=sort(raw-base,'descend');
    while rem>0
        prog=false;
        for ii=ord'
            if rem<=0, break; end
            if base(ii)<cap(ii), base(ii)=base(ii)+1; rem=rem-1; prog=true; end
        end
        if ~prog, break; end
    end
    pos=[];
    for k=1:size(g,1)
        kk=base(k);
        for j=1:kk, pos(end+1)=g(k,1)+(g(k,2)-g(k,1))*j/(kk+1); end %#ok<AGROW>
    end
    pos=sort(pos);
end

function pos = split_cellgrid(g, n, T)
    w=T/n; pos=[];
    for c=0:n-1
        c0=c*w; c1=(c+1)*w; best=-inf; bx=NaN;
        for k=1:size(g,1)
            s=max(g(k,1),c0); e=min(g(k,2),c1);
            if (e-s)>best && (e-s)>0, best=e-s; bx=(s+e)/2; end
        end
        if isfinite(bx), pos(end+1)=bx; end %#ok<AGROW>
    end
    pos=sort(pos);
end
