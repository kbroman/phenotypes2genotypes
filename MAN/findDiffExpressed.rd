\name{find.diff.expressed}
\alias{find.diff.expressed}
\alias{groupLabels}

\title{Finding differentially expressed genes.}

\description{
  Using Rank Product or student t-test analysis to select differentially expressed genes.
}

\usage{
	find.diff.expressed(population,use=c("ttest","rankprod"),verbose=FALSE,debugMode=0,...)
}

\arguments{
\item{population}{ An object of class \code{\link{population}}. See \code{\link{create.population}} for details. }
 \item{use}{ Which method should be used for selecting differentially expressed probes:
  \itemize{
    \item{ttest}{ - student t-test.}
    \item{rankprod}{ - Rank Product using \code{\link{RP}} function.}
  } 
  }
 \item{verbose}{ Be verbose.}
 \item{debugMode}{ 1: Print out checks, 2: print additional time information.}
 \item{...}{ Additional arguments passed to RP function.}
}

\value{
  Object of class \code{\link{population}}.
}

\details{
  This function performs either RankProd or t.test analysis
}

\author{
	Konrad Zych \email{konrad.zych@uj.edu.pl}, Danny Arends \email{Danny.Arends@gmail.com}
	Maintainer: Konrad Zych \email{konrad.zych@uj.edu.pl}
}

\references{
  Hong F, Breitling R, McEntee CW, Wittner BS, Nemhauser JL, Chory J.(2006) RankProd: 
  a bioconductor package for detecting differentially expressed genes in meta-analysis. 
  \emph{Bioinformatics}, \bold{15};22(22):2825-7.
}

\examples{
	data(yeastPopulation)
	yeastPopulation <- find.diff.expressed(yeastPopulation)

}

\seealso{
	\itemize{
    \item{\code{\link[RankProd]{RP}}}{ - Perform rank product method to identify differentially expressed genes.}
    \item{\code{\link{read.population}}}{ - Load genotype, phenotype, genetic map data files into R environment into a population object.}
    \item{\code{\link{generateBiomarkers}}}{ - Creating genotypes from children phenotypes.}
    \item{\code{\link{show.RPpval}}}{- Printing out p-values calculated by the find.diff.expressed function.}
    \item{\code{\link{plot.RPpval}}}{ - Plotting p-values calculated by the find.diff.expressed function.}
  }
}

\keyword{manip}
