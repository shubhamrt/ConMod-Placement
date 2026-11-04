% Figure 4 and Table S2: initial (untreated) flux across the 1,500 plots.
% Shubham Tiwari, 2026

clear; clc; close all;

root = fullfile(fileparts(mfilename('fullpath')),'..');
ddir = fullfile(root,'data'); odir = fullfile(root,'output');
if ~exist(odir,'dir'), mkdir(odir); end
rd = @(f) readtable(fullfile(ddir,f),'TextType','string');
B = rd('flux_baseline.csv');   S = rd('plots_1500.csv');   G = rd('gap_heights.csv');
B.wind_speed=double(B.wind_speed); B.Q=double(B.Q);
S.cover=double(S.cover); S.height=double(S.height); S.largegap=double(S.largegap);
S.n_canopy_gaps=double(S.n_canopy_gaps); G.scaled_gap=double(G.scaled_gap);

types=["grass","mixed","shrub"]; tlab=["Grass","Mixed","Shrub"]; winds=[8 12 16 20];
TCOL=[0.33 0.60 0.36; 0.88 0.62 0.20; 0.55 0.34 0.24];
FT='Helvetica';
set(groot,'defaultAxesFontName',FT,'defaultTextFontName',FT, ...
    'defaultAxesFontSize',12,'defaultAxesLineWidth',1.0,'defaultAxesTitleFontWeight','bold');
figdir=odir;
savefig_pad=@(f,name) print(f,fullfile(figdir,name),'-dpng','-r220');
st=@(x)[numel(x) mean(x) median(x) std(x) pctl(x,75)-pctl(x,25) min(x) max(x)];

%% Table S2
lab={}; M=[];
for j=1:3
    for w=winds
        x=B.Q(B.site_type==types(j) & B.wind_speed==w);
        lab(end+1,:)={char(tlab(j)),num2str(w)}; M(end+1,:)=st(x); %#ok<*SAGROW>
    end
end
for j=1:3, x=B.Q(B.site_type==types(j)); lab(end+1,:)={char(tlab(j)),'All'}; M(end+1,:)=st(x); end
for w=winds, x=B.Q(B.wind_speed==w);   lab(end+1,:)={'All',num2str(w)}; M(end+1,:)=st(x); end
x=B.Q; lab(end+1,:)={'All','All'}; M(end+1,:)=st(x);
Mr=[M(:,1) round(M(:,2:end),1)];
Tbl=table(string(lab(:,1)),string(lab(:,2)),Mr(:,1),Mr(:,2),Mr(:,3),Mr(:,4),Mr(:,5),Mr(:,6),Mr(:,7), ...
    'VariableNames',{'VegType','WindSpeed','N','Mean','Median','Std','IQR','Min','Max'});
try
    writetable(Tbl,fullfile(odir,'table_S2.csv'));
catch ME
    warning('Could not write baseline_flux_stats.csv (%s). Close it if open in Excel, then re-run.',ME.message);
end
disp(Tbl);

%% plot-level flux at 16 m/s
B16=B(B.wind_speed==16,:);
[gp,pid]=findgroups(B16.plot_id); f16p=splitapply(@mean,B16.Q,gp);
[tf,loc]=ismember(S.plot_id,pid); S.f16=nan(height(S),1); S.f16(tf)=f16p(loc(tf));
[gg,pk]=findgroups(G.PrimaryKey); scm=splitapply(@mean,G.scaled_gap,gg);
[t2,l2]=ismember(S.PrimaryKey,pk); S.scaled=nan(height(S),1); S.scaled(t2)=scm(l2(t2));

%% Figure 4
gini=@(x) (2*sum((1:numel(x)).*sort(x(:))')/(numel(x)*sum(x))) - (numel(x)+1)/numel(x);
f=S.f16(~isnan(S.f16)); xf=sort(f); n=numel(xf); Lc=cumsum(xf)/sum(xf); pp=(1:n)/n;
fprintf('Concentration: Gini = %.2f | top 20%% of plots = %.0f%% of flux\n', ...
        gini(f),100*sum(xf(ceil(0.8*n):end))/sum(xf));
f1=figure('Color','w','Position',[40 40 1300 410]);
tl=tiledlayout(f1,1,3,'Padding','compact','TileSpacing','compact');

nexttile; hold on;
fill([0 pp 1],[0 Lc' 1],[0.85 0.90 0.95],'EdgeColor','none');
plot(pp,Lc,'-','Color',[0.18 0.43 0.66],'LineWidth',2);
plot([0 1],[0 1],'k--'); box on; grid on; xlim([0 1]); ylim([0 1]);
set(gca,'XTick',0:0.2:1,'YTick',0:0.2:1);
xlabel('Cumulative fraction of plots'); ylabel('Cumulative fraction of flux');
title('a. Flux concentration across plots','FontWeight','bold');
text(0.06,0.88,sprintf('top 20%% of plots\n= %.0f%% of flux', ...
     100*sum(xf(ceil(0.8*n):end))/sum(xf)),'FontSize',12);

nexttile; hold on;
top10=zeros(3,1); top20=zeros(3,1);
for j=1:3
    x=sort(S.f16(S.site_type==types(j) & ~isnan(S.f16))); m=numel(x);
    top10(j)=100*sum(x(ceil(0.9*m):end))/sum(x);
    top20(j)=100*sum(x(ceil(0.8*m):end))/sum(x);
end
hb=bar([top10 top20]); hb(1).FaceColor=[0.30 0.45 0.65]; hb(2).FaceColor=[0.72 0.80 0.90];
set(gca,'XTick',1:3,'XTickLabel',tlab); box on; grid on; ylim([0 80]);
ylabel('Share of total flux (%)');
legend({'Top 10% of plots','Top 20% of plots'},'Location','northeast','Box','off','FontSize',12);
title('b. Flux share of most erosive plots','FontWeight','bold');

nexttile;
pv={'cover','height','largegap','n_canopy_gaps','scaled'};
plab={'Foliar cover','Height','Gaps > 1 m','No. gaps','Mean scaled gap'};
rho=zeros(numel(pv),1); rci=zeros(numel(pv),2);
rng(7); nb=2000;
for k=1:numel(pv)
    rho(k)=spearman(S.f16,S.(pv{k}));
    ok=find(~isnan(S.f16) & ~isnan(S.(pv{k}))); bs=zeros(nb,1);
    for b=1:nb, ii=ok(randi(numel(ok),numel(ok),1)); bs(b)=spearman(S.f16(ii),S.(pv{k})(ii)); end
    rci(k,:)=[pctl(bs,2.5) pctl(bs,97.5)];
    fprintf('rho %-14s %+.2f  [%+.2f, %+.2f]\n',pv{k},rho(k),rci(k,1),rci(k,2));
end
[rs,oi]=sort(rho); hb=barh(rs); hb.FaceColor='flat'; hold on;
for k=1:numel(rs)
    if rs(k)>=0, hb.CData(k,:)=[0.75 0.22 0.17]; else, hb.CData(k,:)=[0.18 0.43 0.66]; end
end
errorbar(rs,1:numel(rs),rs-rci(oi,1),rci(oi,2)-rs,'horizontal','k.','LineWidth',1.1,'CapSize',5);
set(gca,'YTick',1:numel(pv),'YTickLabel',plab(oi)); box on; grid on; xlim([-0.8 0.8]);
xlabel('Spearman''s \it\rho\rm with initial flux');
title('c. Correlates of initial flux','FontWeight','bold');
savefig_pad(f1,'Figure4_initial_flux.png');

%% local functions
function q=pctl(x,p)
x=sort(x(:)); n=numel(x);
if n==0, q=NaN; return; end
r=p/100*(n-1)+1; lo=floor(r); hi=ceil(r);
if lo==hi, q=x(lo); else, q=x(lo)+(r-lo)*(x(hi)-x(lo)); end
end

function r=spearman(a,b)
a=a(:); b=b(:); m=~isnan(a)&~isnan(b); a=a(m); b=b(m);
ra=tierank(a); rb=tierank(b);
ra=ra-mean(ra); rb=rb-mean(rb);
r=sum(ra.*rb)/sqrt(sum(ra.^2)*sum(rb.^2));
end

function rk=tierank(x)
[~,ord]=sort(x); rk=zeros(size(x)); rk(ord)=1:numel(x);
[u,~,ic]=unique(x);
for k=1:numel(u), idx=(ic==k); if sum(idx)>1, rk(idx)=mean(rk(idx)); end, end
end
