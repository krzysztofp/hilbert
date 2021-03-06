function getNTheoretical  
    oldRecursionLimit = get(0,'RecursionLimit');
    try
        set(0,'RecursionLimit',3000);
        mainBody;
    catch ex
        set(0,'RecursionLimit',oldRecursionLimit);
        throw(ex);
    end
    set(0,'RecursionLimit',oldRecursionLimit);
end

function mainBody
    clc;
    display('The theoretical fit for GaSb');
    tab = GaSb;
    nm = tab(:,1);n = tab(:,2);k=tab(:,3);
    
    [sizexk sizeyk] = size(k);
    l = max(sizexk,sizeyk);
    nmlong = linspace(0,1.1*nm(l),l);
    % CPV Method
    nCpvGaussianKK = ones(l,1);
    nCpvLorentzianKK = ones(l,1);
    for i=1:l, x1 = nm(i); 
           cpvGaussian = @(x)(getGaSbGaussianFun(x)/(x+x1)); nCpvGaussianKK(i) = cpv(0,5000,x1,1500,cpvGaussian); 
           cpvLorentzian = @(x)(getGaSbLorentzianFun(x)/(x+x1)); nCpvLorentzianKK(i) = cpv(0,5000,x1,1500,cpvLorentzian); 
    end
    kApproxGaussian = getGaSbGaussianFun(nmlong);
    kApproxLorentzian = getGaSbLorentzianFun(nmlong);
    
    % Build-in Hilbert Transfortm
    hilbertGaussian = pi*imag(hilbert(kApproxGaussian,l));
    hilbertLorentzian = pi*imag(hilbert(kApproxLorentzian,l));
    
    % Clenshaw-Curtis-33 method
    ccGKGaussian = zeros(1,l);
    ccGKLorentzian = zeros(1,l);
    
    % Adaptation of the quadgk() method
    quadGKGaussian = zeros(1,l);
    quadGKLorentzian = zeros(1,l);
    for  i=1:l, 
        t = nm(i);
        errDef = 0.005;
        f1 = @(x)(getGaSbGaussianFun(x)./(x+t));
        f2 = @(x)(getGaSbLorentzianFun(x)./(x+t));
        
        quadGKGaussian(i) = quadgk(@(x)f1(x)./(x-t),0,t-errDef,'abstol',1e-14,'MaxIntervalCount',500000) + ...
        quadgk(@(x)f1(x)./(x-t),t+errDef, inf,'abstol',1e-14,'MaxIntervalCount',500000); % + ...
        %quadgk(@(x)(f1(t+x)-f1(t-x))./x,0,errDef,'abstol',1e-14,'MaxIntervalCount',500000);
    
        quadGKLorentzian(i) = quadgk(@(x)f2(x)./(x-t),0,t-errDef,'abstol',1e-14,'MaxIntervalCount',500000) + ...
        quadgk(@(x)f2(x)./(x-t),t+errDef, inf,'abstol',1e-14,'MaxIntervalCount',500000); % + ...
        %quadgk(@(x)(f2(t+x)-f2(t-x))./x,0,errDef,'abstol',1e-14,'MaxIntervalCount',500000);        
        
        ccGKGaussian(i) = 2./pi*cauchy(f1,t,0,inf,1e-14); 
        ccGKLorentzian(i) = 2./pi*cauchy(f2,t,0,inf,1e-14); 
    end

    % final plot - Gaussian
    clf,plot(nm,k, ...
             nmlong,kApproxGaussian, ...
             nm,n, ...
             nm,-1000.*nCpvGaussianKK, ...
             nm,-100.*quadGKGaussian, ...
             nm,hilbertGaussian, ...
             nm,-1000.*ccGKGaussian ... 
             ),title('Gaussian'),legend('k','k - approx','n','n - cpv','n - quadgk','n - hilbert','n - cc33');
         
    % final plot - Lorentzian
    figure,clf,plot(nm,k, ...
             nmlong,kApproxLorentzian, ...
             nm,n, ...
             nm,-1000.*nCpvLorentzianKK,...
             nm,-100.*quadGKLorentzian, ...
             nm,hilbertLorentzian, ...
             nm,-1000.*ccGKLorentzian ...
             ),title('Lorentzian'),legend('k','k - approx','n','n - cpv','n - quadgk','n - hilbert','n - cc33');
end
    
function val = getGaSbGaussianFun(x)

    a = [ 0.0000    2.57500    0.04114    1.09800   0.46800   1.11100      0.81220   0.73880];
    b = [47.8     317.8      406.8      509.0     513.5     680.4        788.0     856.3    ];
    c = [33.5       283.5       37.32      82.60     30.48    202.2         53.04     23.45   ];
    
	
    % val = (a0.*exp(-((x-b0)./c0).^2) + a1.*exp(-((x-b1)./c1).^2) + a2.*exp(-((x-b2)./c2).^2) + a3.*exp(-((x-b3)./c3).^2) + a4.*exp(-((x-b4)./c4).^2) ...
    %          + a5.*exp(-((x-b5)./c5).^2) + a6.*exp(-((x-b6)./c6).^2) +
    %          a7.*exp(-((x-b7)./c7).^2));
    val = 0;
    for j=1:8, val = val + a(j).*exp(-((x-b(j))./c(j)).^2); end
end
    
function val = getGaSbLorentzianFun(x)
    amplitude = [323.7 650.8 66.28 226 253.1 128.6 299.9 244.9];
    center = [309.3 515.2 855 786.3 222.3 719.8 413.2 626.1];
    width = [69.35 67.12 21.08 49.25 53.95 48.74 70.68 62.33];

    val = 0;
    for n=1:8, val = val + amplitude(n).*width(n)./((x-center(n)).^2+width(n).^2); end
    val = (1/pi) .* val;

end

function w = cauchy33x(fun,c,t,a,b,tol)  % f - funkcja, c - oscylacje, t - osobliwosc
    e = 0.0025;
    f = fcnchk(fun);
    w = kuadx33(@(x)f(x).*cos(c.*x)./(x-t),a,t-e,tol) + ...
        kuadx33(@(x)f(x).*cos(c.*x)./(x-t),t+e,b,tol) + ...
        kuadx33(@(x)(f(t+x).*cos(c.*(t+x))-f(t-x).*cos(c.*(t-x)))./x,0,e,tol);
end

function w = cauchy(f,t,a,b,tol) % t - osobliwo��, a,b - zasi�g, tol - tolerancja
    e = 0.0025;
    f = fcnchk(f);
    w = quadgk(@(x)f(x)./(x-t),a,t-e,'abstol',tol,'MaxIntervalCount',50000) + ...
        quadgk(@(x)f(x)./(x-t),t+e, b,'abstol',tol,'MaxIntervalCount',50000);% + ...
        % quadgk(@(x)(f(t+x)-f(t-x))./x,0,e,'abstol',tol,'MaxIntervalCount',50000);
end

function [I,fn,qerr] = kuadx33(f,a,b,tol,maxfn,varargin)
    %KUADX33   Triple-adaptive accurate quadrature.
    %   More accurate than KUAD(...) in case of very irregular
    %   integrands and small TOLerance. Syntax is the same
    %   as for KUAD(...) except for there's no trace
    %   due to the nature of KUADX33(...).
    %
    %   I = KUADX33(F,A,B) approximates the integral of the function F
    %   from A to B to within an error of 7*eps. The function Y = F(X)
    %   should accept a vector argument X and return a vector
    %   result Y, the integrand evaluated at each element of X.
    %
    %   I = KUADX33(F,A) is equivalent to I = KUADX33(F,-A,A)
    %   I = KUADX33(F) is equivalent to I = KUADX33(F,0,1)
    %
    %   I = KUADX33(F,A,B,TOL) uses an absolute error tolerance
    %   of TOL instead of the default 7*eps.
    %
    %   [I,FN] = KUADX33(...) returns the number of function evaluations.
    %   [I,FN,ERR] = KUADX33(...) also returns the approximated error.
    %
    %   KUADX33(F,A,B,TOL,MAXFN) defines the maximum number of
    %   function evaluations (the default value is 100000).
    %
    %   KUADX33(FUN,A,B,TOL,MAXFN,P1,P2,...) provides for additional 
    %   arguments P1,P2,... to be passed directly to the function F,
    %   F(X,P1,P2,...). Pass empty matrices for TOL or MAXFN
    %   to use the default values.
    %
    %   Use array operators .*, ./ and .^ in the definition of F
    %   so that it can be evaluated with a vector argument.
    %

    %   P. Keller, 03.12.2009
    %   Algorithm based on Gauss-Legendre rule and 'divide & conquer' rule
    %

    if nargin < 5 || isempty(maxfn)
      maxfn = 3300000;
    end
    if nargin < 4 || isempty(tol)
      tol = 7*eps;
    end
    if nargin < 2
      a = 0; b = 1;
    elseif nargin < 3
      b = a; a = -a;
    end
    if nargin < 1
      error('Function is missing');
    end
    if isnan(b-a)
      error('Incorrect arguments');
    end
    if a==b
      I = 0.0;
      fn = 0;
      qerr = 0.0;
      return
    end
    if a > b
      c = a; a = b; b = c;
      ms = 1;
    else
      ms = 0;
    end

    f = fcnchk(f);
    test_h =  sqrt(3)*(b-a)/7;
    test_x = [ a + test_h; b - test_h ];
    feval(f,test_x,varargin{:}); % test of the function formula

    maxfn = abs(maxfn);
    try
      [I,fn] = kuadxbq(f,a,b,varargin{:});
    catch
      warning('Bad singularity!!!');
    end
    [I,fn,qerr] = kuadxit(f,a,b,tol,maxfn,I,fn,varargin{:});
    qerr = max( qerr, abs(I*eps) );
    if ms == 1, I = -I; end  

    if fn > maxfn
      warning('Maximum function count exceeded; result may be inaccurate')
    end

    %-----------------------------------------------------------------------

    function [I,fn,qerr] = kuadxit(f,a,b,tol,maxfn,I0,fn0,varargin)
        %KUADXIT   Outer iterated recurrence for KUADX33(...).
        %   [I,fn,qerr] = KUADXIT(f,a,b,tol,maxfn,I0,fn0,varargin)
        %   Used in KUADX33(...)

        %   KUADXIT(...) and KUADXRC(...) collect in array R the intervals
        %   for which the desired accuracy was not reached. Then the integrals
        %   in these intervals are recalculated unless the limit for
        %   the number of function evaluations was reached.

        qerr = 1.0; I = I0; fn = fn0;
        R = [ qerr I a b ];

        for step = 1:16
          maxfn1 = floor((maxfn-fn)/size(R,1));
          RR = [];
          for k = 1:size(R,1)
            qerr0 = R(k,1); I0 = R(k,2); a = R(k,3); b = R(k,4);
            minl = 2*fn0*(b-a) / maxfn1;
            [I1,fn,qerr1,R1] = kuadxrc(f,a,b,tol,minl,I0,fn,varargin{:});
            I = I + (I1-I0);
            qerr = qerr + (qerr1-qerr0);
            RR = [ RR ; R1 ];
            if fn >= maxfn
              if mod(k,2) == 0
                break
              end  
            end  
          end
          if fn >= maxfn || size(RR,1) == 0
            break
          end  
          R = sortrows(RR);
          R = R(end:-1:1,:);
        end
    end
    %-----------------------------------------------------------------------

    function [I,fn,qerr,R] = kuadxrc(f,a,b,tol,minl,I0,fn0,varargin)
        %KUADXRC   Adaptive Gauss quadrature rule.
        %   [I,fn,qerr,R] = KUADXRC(f,a,b,tol,minl,I0,fn0,varargin)
        %   Used in KUADX33(...)

        %   KUADXIT(...) and KUADXRC(...) collect in array R the intervals
        %   for which the desired accuracy was not reached. Then the integrals
        %   in these intervals are recalculated unless the limit for
        %   the number of function evaluations was reached.

        s = (a+b)/2;
        try
          [I1,fn,m1] = kuadxbq(f,a,s,varargin{:});
          [I2,fn,m2] = kuadxbq(f,s,b,varargin{:});
        % tol = max( tol, 0.375*max(m1,m2)*eps/fn );
          qerr = abs(I1+I2-I0) * max(1.0,-log10(b-a)*0.125);
          fn = fn0 + 2*fn;
        catch
          I1 = 0.5*I0;
          I2 = I1;
          fn = fn0;
          qerr = abs(0.5*I0);
          tol = 2.0*qerr;
          warning('Singularity detected; result is likely inaccurate');
        end

        if qerr <= tol || (s-a) < minl
          if qerr > tol
          % R = [ 0.25*qerr I1 a s ; 0.25*qerr I2 s b ];
            R = [ 0.5*qerr I1 a s ; 0.5*qerr I2 s b ];
          else
            R = [];
          end  
          I = I1 + I2;
        % qerr = 0.5*qerr;  
        else
          R = [];
          [I1,fn,e1,R1] = kuadxrc(f,a,s,0.875*tol,minl,I1,fn,varargin{:});
          [I2,fn,e2,R2] = kuadxrc(f,s,b,0.875*tol,minl,I2,fn,varargin{:});
          R = [ R; R1; R2 ];
          qerr = e1 + e2;
          I = I1 + I2;
        end
    end

    %-----------------------------------------------------------------------

    function [I,fn,m] = kuadxbq(f,a,b,varargin)
        %KUADXBQ   Basic quadrature rule (33 points Gauss-Legendre).
        %   [I,fn] = KUADXBQ(f,a,b,varargin)
        %   Used in KUADX33(...)

        w = [
          3.114570277954342359303230536e-03
          7.225081374297517707601105164e-03
          1.128186099274748504204704436e-02
          1.524569031922306590472119384e-02
          1.908329689819375816088296014e-02
          2.276280576167663622691128170e-02
          2.625370728633905308412298742e-02
          2.952706791376224659698048618e-02
          3.255576077703820568927221503e-02
          3.531468790712786249951939828e-02
          3.778098733001596563541698711e-02
          3.993422216988592236940941640e-02
          4.175654984992282759351011402e-02
          4.323286987351787489212342814e-02
          4.435094891784693464353822868e-02
          4.510152218532036478697112101e-02
          4.547837016512993680766880197e-02
          4.547837016512993680766880197e-02
          4.510152218532036478697112101e-02
          4.435094891784693464353822868e-02
          4.323286987351787489212342814e-02
          4.175654984992282759351011402e-02
          3.993422216988592236940941640e-02
          3.778098733001596563541698711e-02
          3.531468790712786249951939828e-02
          3.255576077703820568927221503e-02
          2.952706791376224659698048618e-02
          2.625370728633905308412298742e-02
          2.276280576167663622691128170e-02
          1.908329689819375816088296014e-02
          1.524569031922306590472119384e-02
          1.128186099274748504204704436e-02
          7.225081374297517707601105164e-03
          3.114570277954342359303230536e-03
        ]';
        x = [
          1.214123104579040378313781273e-03
          6.386091796845257475124784450e-03
          1.564586873332785911767671347e-02
          2.891880129744645418416198727e-02
          4.609516114083776559955005549e-02
          6.703268083271776536821395466e-02
          9.155788604953316770421054671e-02
          1.194675616850634929062955155e-01
          1.505304433918685460334999467e-01
          1.844891364597357273411121222e-01
          2.210622496651266786317700569e-01
          2.599467274048364829029486597e-01
          3.008203611206770296842526235e-01
          3.433444593302683762708416172e-01
          3.871666541917752580656794095e-01
          4.319238213704085120527855878e-01
          4.772450890234487286254621646e-01
          5.227549109765512713745378354e-01
          5.680761786295914879472144122e-01
          6.128333458082247419343205905e-01
          6.566555406697316237291583828e-01
          6.991796388793229703157473765e-01
          7.400532725951635170970513403e-01
          7.789377503348733213682299431e-01
          8.155108635402642726588878778e-01
          8.494695566081314539665000533e-01
          8.805324383149365070937044845e-01
          9.084421139504668322957894533e-01
          9.329673191672822346317860453e-01
          9.539048388591622344004499445e-01
          9.710811987025535458158380127e-01
          9.843541312666721408823232865e-01
          9.936139082031547425248752155e-01
          9.987858768954209596216862187e-01
        ];

        x = feval(f, (b-a)*x + a, varargin{:});
        m = max(abs(x));
        if m == Inf
          error('Singularity detected');
        end
        w = (b-a)*w;
        I = w*x;
        fn = max(size(x));

    %--------------------------------------------------------------- KUADX -

    end
end
    
function I = cc(fun,n)
    % Kwadratura C-C - (n+1)-punktowa
    f = fcnchk(fun);                            % Akceptuj rozne formy funkcji

    x = cos(pi*(0:n)'/n);                       % wezly Czebyszewa
    fx = feval(f,x)/(2*n);                      % Wartosci f w tych wezlach
    g = real(fft(fx([1:n+1 n:-1:2])));          % Szybka transformacja Fouriera
    a = [g(1); g(2:n)+g(2*n:-1:n+2); g(n+1)];   % Wspolczynniki Czebyszewa

    w = 0*a'; w(1:2:end) = 2./(1-(0:2:n).^2);   % Calki z wiel. Czebyszewa
    % I = w*a;                                  % Calka funkcji f
    I = w(end:-1:1)*a(end:-1:1);                % Tak lepiej sumowac!
end