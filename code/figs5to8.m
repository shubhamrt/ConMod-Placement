% Figures 5-8: placement results at U = 16 m/s. Run build_results.py first.
% Shubham Tiwari, 2026

clear; clc; close all;
odir=fullfile(fileparts(mfilename('fullpath')),'..','output');
rd=@(f) readtable(fullfile(odir,f),'TextType','string');
M=rd('master_results.csv'); C=rd('contrasts_bootstrap.csv'); R=rd('regret.csv');
Rel=rd('reliability.csv'); MB=rd('marginal_benefit.csv');
num=@(T,c) double(T.(c));
for c={'density','wind_speed','pct','per_avoided','perha_avoided','ach_density','base_gmd','Q_avoided'}, M.(c{1})=num(M,c{1}); end
for c={'wind_speed','density','median_diff'}, C.(c{1})=num(C,c{1}); end
C.sig=ismember(lower(string(C.sig)),["true","1"]); R.win_rate=num(R,'win_rate');
for c={'wind_speed','density','median_pct'}, Rel.(c{1})=num(Rel,c{1}); end
for c={'wind_speed','from_density','to_density','marg_per_structure','marg_perha'}, MB.(c{1})=num(MB,c{1}); end
CC=M(ismember(lower(string(M.complete_case)),["true","1"]),:);

types=["grass","mixed","shrub"]; tlab=["Grass","Mixed","Shrub"];
modes=["targeted","scaled","proportional","cellgrid"];
mlab={'Largest-gap','Scaled gap','Proportional','Cell-grid'};
COL=[0.18 0.43 0.66; 0.75 0.22 0.17; 0.50 0.50 0.50; 0.20 0.55 0.35];
TCOL=[0.30 0.62 0.35; 0.20 0.45 0.72; 0.90 0.56 0.16];
dvals=[100 250 500 1000 2000 4000]; W=16; BAND=[100 1000]; NM=numel(modes);
FT='Helvetica'; set(groot,'defaultAxesFontName',FT,'defaultTextFontName',FT,'defaultAxesFontSize',11);
figdir=odir;

%% Figure 5
permax=0; qmax=0;
for j=1:3, for k=1:NM
    [ym,yci]=mci(CC,types(j),W,modes(k),'perha_avoided',dvals); permax=max(permax,max(ym+yci));
    [ym,yci]=mci(CC,types(j),W,modes(k),'Q_avoided',dvals);     qmax  =max(qmax,  max(ym+yci));
end, end
Nt=arrayfun(@(t) numel(unique(CC.plot_id(CC.site_type==t & CC.wind_speed==W))),types);
f4=figure('Color','w','Position',[40 40 1180 1020]);
tl=tiledlayout(f4,3,3,'TileSpacing','compact','Padding','compact'); hL=gobjects(1,NM); axA=gobjects(1);
letters={'a','b','c';'d','e','f';'g','h','i'};
ylabs={'Mean flux reduction (%)', ...
       'Mean flux reduction (g m^{-1} d^{-1})', ...
       {'Reduction efficiency','(g m^{-1} d^{-1} per structure ha^{-1})'}};
for r=1:3
    fld="pct"; yl=[0 100];
    if r==2, fld="Q_avoided"; yl=[0 qmax*1.05]; end
    if r==3, fld="perha_avoided"; yl=[0 permax*1.05]; end
    for j=1:3
        ax=nexttile(tl); hold(ax,'on');
        ax.Toolbar.Visible='off';   % keeps the "..." overlay out of the export
        for k=1:NM
            [ym,yci]=mci(CC,types(j),W,modes(k),fld,dvals);
            fill(ax,[dvals fliplr(dvals)],[ym-yci fliplr(ym+yci)],COL(k,:),'FaceAlpha',0.13,'EdgeColor','none','HandleVisibility','off');
            hh=plot(ax,dvals,ym,'-o','Color',COL(k,:),'MarkerFaceColor',COL(k,:),'MarkerSize',4.5,'LineWidth',1.8);
            if r==1&&j==1, hL(k)=hh; axA=ax; end
             
        end
        set(ax,'XScale','log','XTick',dvals,'XTickLabel',dvals); grid(ax,'on'); box(ax,'on'); ax.Layer='top'; ylim(ax,yl);xlim([90 5000])
        ax.XMinorGrid='off'; ax.XMinorTick='off'; ax.GridAlpha=0.12;
        if r==1
            title(ax,sprintf('(%s) %s (n = %d)',letters{1,j},tlab(j),Nt(j)),'FontWeight','bold');
        else
            text(ax,0,1.01,sprintf('(%s)',letters{r,j}),'Units','normalized','FontWeight','bold','VerticalAlignment','bottom');
        end
        if r<3, set(ax,'XTickLabel',[]); else, xtickangle(ax,0); end
        if j==1
            yh=ylabel(ax,ylabs{r},'FontSize',10);
            set(yh,'Units','normalized','Position',[-0.22 0.5 0],'HorizontalAlignment','center','VerticalAlignment','top');
        end
    set(gca,'fontsize',10)
   
    end
end
lg=legend(axA,hL,mlab,'Orientation','horizontal','Box','off','FontSize',10);
lg.Layout.Tile='north';
xlabel(tl,'Prescribed structure density (structures ha^{-1})','FontName',FT,'FontSize',11);
exportgraphics(f4,fullfile(figdir,'Figure5_density.png'),'Resolution',300,'Padding',18);
exportgraphics(f4,fullfile(figdir,'Figure5_density.pdf'),'ContentType','vector','Padding',18);

%% Figure 6
S=C(C.contrast=="scaled_minus_largest",:); winds=[12 16 20];
cl=15; cmap=divmap(256);   % fixed symmetric colour scale, -15 to +15 pp
Wpx=1150; Hpx=560;
f5=figure('Color','w','Position',[40 40 Wpx Hpx]); colormap(f5,cmap); axH=gobjects(1,3);
xL=0.075; wH=0.262; gH=0.030; yH=0.58; hH=wH*Wpx/(2*Hpx);   % hH makes each 6x3 cell square
xHs=xL+(0:2)*(wH+gH); L={'a','b','c'};
for wi=1:3
    w=winds(wi); ax=axes('Parent',f5,'Position',[xHs(wi), yH, wH, hH]); hold(ax,'on'); axH(wi)=ax;
    Mx=nan(3,6); SG=false(3,6);
    for r=1:3, for c=1:6
        row=S(S.wind_speed==w & S.site_type==types(r) & S.density==dvals(c),:);
        if ~isempty(row), Mx(r,c)=row.median_diff(1); SG(r,c)=row.sig(1); end
    end, end
    imagesc(ax,Mx); clim(ax,[-cl cl]);
    set(ax,'YDir','reverse','XLim',[0.5 6.5],'YLim',[0.5 3.5],'XTick',1:6,'XTickLabel',dvals, ...
        'YTick',1:3,'FontSize',11,'Box','on','XTickLabelRotation',0);
    if wi==1, set(ax,'YTickLabel',tlab); ylabel(ax,'Vegetation type','FontSize',11); else, set(ax,'YTickLabel',[]); end
    for r=1:3, for c=1:6
        if ~isnan(Mx(r,c))
            if SG(r,c), s=sprintf('%+.1f^{*}',Mx(r,c)); else, s=sprintf('%+.1f',Mx(r,c)); end   % superscript asterisk
            tc=[0 0 0]; if abs(Mx(r,c))>0.62*cl, tc=[1 1 1]; end
            text(ax,c,r,s,'HorizontalAlignment','center','FontSize',11,'Color',tc);
        end
    end, end
    for xg=1.5:5.5, plot(ax,[xg xg],[0.5 3.5],'-','Color',[1 1 1 .6],'LineWidth',0.75); end
    for yg=1.5:2.5, plot(ax,[0.5 6.5],[yg yg],'-','Color',[1 1 1 .6],'LineWidth',0.75); end
    title(ax,sprintf('(%s) Wind Speed = %d m s^{-1}',L{wi},w),'FontWeight','bold','FontSize',11);
end
annotation(f5,'textbox',[xL, 0.505, xHs(3)+wH-xL, 0.035],'String','Prescribed structure density (n ha^{-1})', ...
    'EdgeColor','none','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',11,'FontName',FT);
cb=colorbar(axH(3),'Position',[xHs(3)+wH+0.012, yH, 0.016, hH],'FontSize',10);
cb.Label.String='Scaled gap − largest-gap (percentage points)'; cb.Label.FontSize=10;
annotation(f5,'textbox',[0.66, 0.44, 0.33, 0.04],'String','*  paired 95% CI excludes 0', ...
    'EdgeColor','none','FontSize',9,'FontName',FT);
axw=axes('Parent',f5,'Position',[xL, 0.12, xHs(3)+wH-xL, 0.24]); hold(axw,'on');
WR=rd('winrate.csv');
wr=arrayfun(@(m) 100*double(WR.win_rate(WR.mode==m)), modes);
b=barh(axw,wr,0.6); b.FaceColor='flat'; for k=1:4, b.CData(k,:)=COL(k,:); end
set(axw,'YTick',1:4,'YTickLabel',mlab,'YDir','reverse','FontSize',11); xlim(axw,[0 50]); grid(axw,'on'); box(axw,'on');
for k=1:4, text(axw,wr(k)+0.6,k,sprintf('%.1f%%',wr(k)),'VerticalAlignment','middle','FontSize',10); end
xlabel(axw,'Share of evaluated combinations (%)','FontSize',11);
text(axw,0,1.08,'(d)','Units','normalized','FontWeight','bold','FontSize',11,'VerticalAlignment','bottom','HorizontalAlignment','left');
exportgraphics(f5,fullfile(figdir,'Figure6_strategy_comparison.png'),'Resolution',300,'Padding',18);
exportgraphics(f5,fullfile(figdir,'Figure6_strategy_comparison.pdf'),'ContentType','vector','Padding',18);

%% Figure 7
f6=figure('Color','w','Position',[30 30 1350 420]);
tl=tiledlayout(f6,1,3,'TileSpacing','compact','Padding','compact');
ax=nexttile(tl); hold(ax,'on'); hL=gobjects(1,NM);
r11=plot(ax,[80 5000],[80 5000],'--','Color',[0.6 0.6 0.6],'LineWidth',1.4);
plot(ax,[100 100],[80 5000],':','Color',[0.45 0.45 0.45],'LineWidth',1.1,'HandleVisibility','off');
for k=1:NM
    y=arrayfun(@(d) mean(CC.ach_density(CC.mode==modes(k)&CC.wind_speed==W&CC.density==d),'omitnan'),dvals);
    hL(k)=plot(ax,dvals,y,'-o','Color',COL(k,:),'MarkerFaceColor',COL(k,:),'LineWidth',1.8,'MarkerSize',5);
end
set(ax,'XScale','log','YScale','log','XTick',dvals,'XTickLabel',dvals,'YTick',dvals,'YTickLabel',dvals);
axis(ax,[80 5000 80 5000]); grid(ax,'on'); box(ax,'on'); xtickangle(ax,0);
xlabel(ax,'Prescribed density (structures ha^{-1})'); ylabel(ax,'Achieved density (structures ha^{-1})');
text(ax,1000,1450,'Achieved = prescribed','Rotation',45,'FontSize',8,'Color',[0.5 0.5 0.5],'FontName',FT);
title(ax,'(a)','FontWeight','bold','FontSize',11);
legend(ax,hL,mlab,'Location','northwest','Box','off','FontSize',9);
ax=nexttile(tl); hold(ax,'on'); targets=[50 75 90]; Mthr=nan(3,3);
for ti=1:3
    sub=sortrows(Rel(Rel.site_type==types(ti)&Rel.mode=="targeted"&Rel.wind_speed==W,:),'density');
    for g=1:3, ok=sub(sub.median_pct>=targets(g),:); if ~isempty(ok), Mthr(ti,g)=min(ok.density); end, end
end
hB=gobjects(1,3);
for ti=1:3
    hB(ti)=plot(ax,targets+(ti-2)*0.9,Mthr(ti,:),'-o','Color',TCOL(ti,:),'MarkerFaceColor',TCOL(ti,:),'LineWidth',1.8,'MarkerSize',6);
end
set(ax,'YScale','log','YTick',dvals,'YTickLabel',dvals,'XTick',targets); grid(ax,'on'); box(ax,'on');
xlim(ax,[45 95]); ylim(ax,[80 5000]);
plot(ax,[45 95],[100 100],':','Color',[0.45 0.45 0.45],'LineWidth',1.1,'HandleVisibility','off');
text(ax,94,118,'Entry-level: 100 structures ha^{-1}','FontSize',8,'Color',[0.45 0.45 0.45], ...
     'HorizontalAlignment','right','VerticalAlignment','bottom');
xlabel(ax,'Flux-reduction target (%)'); ylabel(ax,'Minimum tested density (structures ha^{-1})');
title(ax,'(b)','FontWeight','bold','FontSize',11);
legend(ax,hB,tlab,'Location','northwest','Box','off','FontSize',9);
ax=nexttile(tl); hold(ax,'on'); hT=gobjects(1,3);
for ti=1:3
    sub=sortrows(MB(MB.site_type==types(ti)&MB.mode=="targeted"&MB.wind_speed==W,:),'from_density');
    hT(ti)=plot(ax,sub.to_density,sub.marg_perha,'-o','Color',TCOL(ti,:),'MarkerFaceColor',TCOL(ti,:),'LineWidth',1.8,'MarkerSize',5);
end
set(ax,'XScale','log','XTick',dvals,'XTickLabel',dvals); grid(ax,'on'); box(ax,'on'); xlim(ax,[80 5000]); xtickangle(ax,0);
xlabel(ax,'Upper density of increment (structures ha^{-1})'); ylabel(ax,{'Marginal reduction efficiency','(g m^{-1} d^{-1} per structure ha^{-1})'});
title(ax,'(c)','FontWeight','bold','FontSize',11); legend(ax,hT,tlab,'Location','northeast','Box','off','FontSize',9);
exportgraphics(f6,fullfile(figdir,'Figure7_deployment.png'),'Resolution',300,'Padding',18);
exportgraphics(f6,fullfile(figdir,'Figure7_deployment.pdf'),'ContentType','vector','Padding',18);

%% Figure 8
dens7=[250 500 1000]; c7=[0.66 0.78 0.90; 0.30 0.50 0.72; 0.10 0.26 0.50];
f7=figure('Color','w','Position',[60 60 720 560]); ax=axes(f7); hold(ax,'on'); h7=gobjects(1,numel(dens7));
marks=[5 10 25 50];
for di=1:numel(dens7)
    d=dens7(di); sub=CC(CC.mode=="targeted"&CC.wind_speed==W&CC.density==d,:);
    [~,ix]=sort(sub.base_gmd,'descend'); av=sub.Q_avoided(ix);
    xq=(1:height(sub))'/height(sub)*100; yc=cumsum(av)/sum(sub.base_gmd)*100;
    plot(ax,[0 100],[0 yc(end)],'--','Color',c7(di,:),'LineWidth',1.2,'HandleVisibility','off');
    h7(di)=plot(ax,xq,yc,'-','Color',c7(di,:),'LineWidth',2.4);                                     % highest-flux plots first
    text(ax,101,yc(end),sprintf('%.0f%%',yc(end)),'Color',c7(di,:),'FontSize',9,'FontWeight','bold','VerticalAlignment','middle','Clipping','off');
    if d==1000
        for mm=marks
            k=max(1,round(mm/100*height(sub))); plot(ax,xq(k),yc(k),'o','Color',c7(di,:),'MarkerFaceColor','w','MarkerSize',6,'LineWidth',1.5);
            text(ax,xq(k)+1.5,yc(k)-1.2,sprintf('%.0f%%',yc(k)),'FontSize',9,'Color',c7(di,:));
        end
    end
end
grid(ax,'on'); box(ax,'on'); xlim(ax,[0 100]); ylim(ax,[0 60]);
xlabel(ax,'Highest-flux plots treated (%)'); ylabel(ax,'Aggregate flux reduction (% of sample-wide untreated flux)');
lx=63; lw=3.5; yr=[12 9.5 7];
for di=1:3
    plot(ax,[lx lx+lw],[yr(di) yr(di)],'-','Color',c7(di,:),'LineWidth',2.4);
    text(ax,lx+lw+1,yr(di),sprintf('%d structures ha^{-1}',dens7(di)),'FontSize',9,'VerticalAlignment','middle','FontName',FT);
end
xb=lx-1.4; yb=[min(yr)-0.6 max(yr)+0.6];
plot(ax,[xb xb],yb,'-','Color',[0.5 0.5 0.5],'LineWidth',1);
plot(ax,[xb xb+0.7],[yb(1) yb(1)],'-','Color',[0.5 0.5 0.5],'LineWidth',1);
plot(ax,[xb xb+0.7],[yb(2) yb(2)],'-','Color',[0.5 0.5 0.5],'LineWidth',1);
text(ax,xb-0.6,mean(yr),'Highest-flux first','FontSize',9,'HorizontalAlignment','right','VerticalAlignment','middle','Color',[0.3 0.3 0.3],'FontName',FT);
plot(ax,[lx lx+lw],[4.5 4.5],'--','Color',[0.35 0.35 0.35],'LineWidth',1.2);
text(ax,lx+lw+1,4.5,'Unprioritized expectation','FontSize',9,'VerticalAlignment','middle','FontName',FT);
exportgraphics(f7,fullfile(figdir,'Figure8_prioritization.png'),'Resolution',300,'Padding',18);
exportgraphics(f7,fullfile(figdir,'Figure8_prioritization.pdf'),'ContentType','vector','Padding',18);
fprintf('Saved Figures 5-8 to %s\n',figdir);

%% local functions
function [ym,yci]=mci(T,t,w,m,fld,dvals)
    ym=zeros(1,numel(dvals)); yci=ym;
    for i=1:numel(dvals)
        v=T.(fld)(T.site_type==t & T.wind_speed==w & T.mode==m & T.density==dvals(i));
        v=v(~isnan(v)); n=numel(v); ym(i)=mean(v); if n>1, yci(i)=1.96*std(v)/sqrt(n); end
    end
end
function cm=divmap(n)
    cB=[0.13 0.30 0.55]; cW=[1 1 1]; cR=[0.70 0.12 0.12];
    h=floor(n/2); t=linspace(0,1,h)'; cm=[(1-t).*cB + t.*cW; (1-t).*cW + t.*cR];
end
