/* gatherhostnames.c (2016-01-18) */

/* Gather and print processor names on rank0.  It is used to recover a
   host-list of the job (it returns only static processes). */

#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <limits.h>
#include <assert.h>

#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

// Returns hostname for the local computer
void checkHostName(int hostname)
{
        if (hostname == -1)
        {
                perror("gethostname");
                exit(1);
        }
}

// Returns host information corresponding to host name
void checkHostEntry(struct hostent * hostentry)
{
        if (hostentry == NULL)
        {
                perror("gethostbyname");
                exit(1);
        }
}

// Converts space-delimited IPv4 addresses
// to dotted-decimal format
void checkIPbuffer(char *IPbuffer)
{
        if (NULL == IPbuffer)
        {
                perror("inet_ntoa");
                exit(1);
        }
}


int
main(int argc, char *argv[])
{
    if (argc != 2) {
	fprintf(stderr, "Usage mpiexec -n N gatherhostnames filename\n");
	fflush(0);
	return 1;
    }

    MPI_Init(&argc, &argv);

	char hostbuffer[256];
	char *IPbuffer;
	struct hostent *host_entry;
	int hostname;

	// To retrieve hostname
	hostname = gethostname(hostbuffer, sizeof(hostbuffer));
	checkHostName(hostname);

	// To retrieve host information
	host_entry = gethostbyname(hostbuffer);
	checkHostEntry(host_entry);


    int nprocs, rank;
    MPI_Comm_size(MPI_COMM_WORLD, &nprocs);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);

    char name[MPI_MAX_PROCESSOR_NAME];
    char names[nprocs][MPI_MAX_PROCESSOR_NAME];
	int namelen;
    MPI_Get_processor_name(name, &namelen);
    name[MPI_MAX_PROCESSOR_NAME - 1] = 0;
    MPI_Gather(name, sizeof(name), MPI_CHAR,
               names, sizeof(name), MPI_CHAR,
               0, MPI_COMM_WORLD);	
	// Get the ipaddress and gather it. 
	int IP_SIZE=16;
    char ip_address[nprocs][IP_SIZE];
	IPbuffer = inet_ntoa(*((struct in_addr*)host_entry->h_addr_list[0]));
    MPI_Gather(IPbuffer, IP_SIZE, MPI_CHAR,
               ip_address, IP_SIZE, MPI_CHAR,
               0, MPI_COMM_WORLD);

    if (rank == 0) {
	FILE * f = fopen(argv[1], "w");
	if (f == 0) {
	    int e = errno;
	    char b[80];
	    snprintf(b, sizeof(b), "fopen(%s)", argv[1]);
	    perror(b);
	    MPI_Abort(MPI_COMM_WORLD, 1);
	    return 1;
	} else {
	    for (int i = 0; i < nprocs; i++) {
			fprintf(f, "%s ", ip_address[i]);
			fprintf(f, "%s\n", names[i]);			
	    }
	    fflush(f);
	    fclose(f);
	}
    }

    MPI_Barrier(MPI_COMM_WORLD);
    MPI_Finalize();

    return 0;
}

